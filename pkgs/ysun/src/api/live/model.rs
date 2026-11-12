use std::collections::HashMap;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use jiff::{Timestamp, Unit};
use serde::Serialize;

/// one poll per minute, at an offset of the host's own
pub const INTERVAL: Duration = Duration::from_secs(60);
/// ceiling for the backoff after 429 and 5xx answers
pub const MAX_INTERVAL: Duration = Duration::from_secs(300);
/// delay from the start of a play to apple's history entry, about 2 s in the 2026-11-11 probes
pub const LAG: Duration = Duration::from_secs(2);
/// an auth failure this long after the last success means the tokens are dead rather than apple
/// flaking
pub const DEAD_AFTER: Duration = Duration::from_secs(15 * 60);
/// three times the 72 px the card shows on wide screens
pub const ARTWORK_SIZE: u32 = 216;

/// isrc prefixes that name no country: international, the us codes for distributors, and tc,
/// which is turks and caicos in iso 3166 but was seen on a tunecore japan release
const NO_COUNTRY: [&str; 5] = ["zz", "qm", "qt", "qz", "tc"];

/// serialized as the response's track
#[derive(Serialize)]
pub struct Track {
    pub title: String,
    pub artist: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub album: Option<String>,
    /// language of title, artist and album
    pub lang: String,
    /// milliseconds, nonzero, none when apple gives none or zero
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub artwork: Option<String>,
}

pub struct Snapshot {
    pub track: Track,
    /// estimated start, none when the play began before this process saw it
    pub start: Option<Instant>,
    /// the same start on the wall clock, for display, since apple's history carries no times
    pub played: Option<Timestamp>,
}

/// serialized as the response's state and position
#[derive(Serialize)]
#[serde(tag = "state", rename_all = "lowercase")]
pub enum State {
    /// position in milliseconds, capped at the duration
    Playing { position: u64 },
    /// nothing plays, the track is the last one played
    Waiting,
}

impl Snapshot {
    pub fn state(&self, now: Instant) -> State {
        let (Some(start), Some(duration)) = (self.start, self.track.duration) else {
            return State::Waiting;
        };
        let duration = Duration::from_millis(duration);
        let elapsed = now.saturating_duration_since(start);
        // the next track can show up as late as one interval after this one ended
        if elapsed < duration + LAG + INTERVAL {
            State::Playing {
                position: elapsed.min(duration).as_millis() as u64,
            }
        } else {
            State::Waiting
        }
    }
}

pub enum Step {
    Keep,
    /// publish this head, with a start when it is a play this process saw begin
    New {
        start: Option<Instant>,
    },
}

/// what the poll keeps between ticks
#[derive(Default)]
pub struct Tracker {
    head: Option<String>,
    polled: Option<Instant>,
    dead: bool,
}

impl Tracker {
    /// a successful history call, with the id of its newest entry if there is one
    pub fn success(&mut self, now: Instant, head: Option<&str>) -> Step {
        let previous = self.polled.replace(now);
        let Some(head) = head else {
            return Step::Keep;
        };
        let step = match &self.head {
            Some(known) if known == head && !self.dead => return Step::Keep,
            Some(_) if !self.dead => Step::New {
                start: previous.map(|previous| estimate(previous, now)),
            },
            // the first head after a start or after dying may have begun long ago
            _ => Step::New { start: None },
        };
        self.head = Some(head.to_owned());
        self.dead = false;
        step
    }

    /// true for the failure that declares the tokens dead
    pub fn failure(&mut self, now: Instant, auth: bool) -> bool {
        let dead = auth
            && !self.dead
            && self
                .polled
                .is_some_and(|polled| now.saturating_duration_since(polled) >= DEAD_AFTER);
        self.dead |= dead;
        dead
    }
}

/// the play began between the previous poll and this one, less apple's lag, so take the middle
pub fn estimate(previous: Instant, now: Instant) -> Instant {
    now - (LAG + now.saturating_duration_since(previous) / 2)
}

/// the wall clock time of an instant to the second, given the two clocks read together
pub fn wall(at: Instant, now: Instant, clock: Timestamp) -> Timestamp {
    clock
        .checked_sub(now.saturating_duration_since(at))
        .and_then(|time| time.round(Unit::Second))
        .expect("an instant of this process is within jiff's range")
}

/// the storefront whose metadata is the release's own, when it is not the account's
pub fn origin<'a>(
    isrc: &str,
    account: &str,
    storefronts: &'a HashMap<String, String>,
) -> Option<&'a str> {
    let country = isrc.get(..2)?.to_ascii_lowercase();
    if country == account || NO_COUNTRY.contains(&country.as_str()) {
        return None;
    }
    storefronts
        .get_key_value(&country)
        .map(|(id, _)| id.as_str())
}

/// apple's artwork urls are templates with {w} and {h}
pub fn artwork(template: &str) -> String {
    let size = ARTWORK_SIZE.to_string();
    template.replace("{w}", &size).replace("{h}", &size)
}

/// time until the next instant of the wall clock that is offset past a multiple of the interval
pub fn delay(now: SystemTime, offset: Duration, interval: Duration) -> Duration {
    let now = now
        .duration_since(UNIX_EPOCH)
        .expect("the clock is past 1970")
        .as_millis();
    let period = interval.as_millis();
    let phase = (now + period - offset.as_millis() % period) % period;
    Duration::from_millis((period - phase) as u64)
}
