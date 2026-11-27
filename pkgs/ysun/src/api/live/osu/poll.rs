use std::io;
use std::panic::{self, AssertUnwindSafe};
use std::process;
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

use tokio::sync::watch;

use super::client::{Difficulty, Failure, Osu, Recent};
use super::model::{DEAD_AFTER, INTERVAL, MAX_INTERVAL, Map, Play, Score, USER, lang};

pub struct Poll {
    osu: Osu,
    publish: watch::Sender<Option<Arc<Play>>>,
    interval: Duration,
    /// the score on show
    head: Option<u64>,
    /// the last successful poll
    polled: Option<Instant>,
    /// a failure streak was already reported
    reported: bool,
}

impl Poll {
    pub fn new(osu: Osu, publish: watch::Sender<Option<Arc<Play>>>) -> Poll {
        Poll {
            osu,
            publish,
            interval: INTERVAL,
            head: None,
            polled: None,
            reported: false,
        }
    }

    /// runs the poll on a thread of its own for the life of the process, and a panic there exits the
    /// process, since a dead poll would leave a stale play behind
    pub fn spawn(self) -> io::Result<()> {
        thread::Builder::new()
            .name("osu".to_owned())
            .spawn(move || {
                // the panic hook has already printed the panic
                let _ = panic::catch_unwind(AssertUnwindSafe(|| self.run()));
                process::exit(1);
            })
            .map(drop)
    }

    /// the first tick runs at once
    fn run(mut self) -> ! {
        loop {
            self.tick(Instant::now());
            thread::sleep(self.interval);
        }
    }

    fn tick(&mut self, now: Instant) {
        match self.osu.recent(USER) {
            Ok(recent) => {
                self.interval = INTERVAL;
                self.reported = false;
                self.polled = Some(now);
                match recent {
                    Some(recent) if self.head != Some(recent.id) => {
                        let difficulty = self
                            .osu
                            .difficulty(&recent)
                            .map_err(|failure| {
                                eprintln!(
                                    "osu: {failure} looking up beatmap {}, showing its rating without mods",
                                    recent.beatmap.id
                                )
                            })
                            .ok();
                        self.head = Some(recent.id);
                        self.publish
                            .send_replace(Some(Arc::new(play(recent, difficulty))));
                    }
                    Some(_) => {}
                    None => {
                        if self.head.take().is_some() {
                            self.publish.send_replace(None);
                        }
                    }
                }
            }
            Err(failure) => {
                self.interval = (self.interval * 2).min(MAX_INTERVAL);
                let dead = matches!(failure, Failure::Auth(_))
                    && self.head.is_some()
                    && self
                        .polled
                        .is_some_and(|polled| now.saturating_duration_since(polled) >= DEAD_AFTER);
                if dead {
                    eprintln!(
                        "osu: {failure} {} minutes after the last success, clearing the play until a poll succeeds",
                        DEAD_AFTER.as_secs() / 60
                    );
                    self.head = None;
                    self.publish.send_replace(None);
                } else if !self.reported {
                    eprintln!("osu: {failure}, keeping the last play");
                }
                self.reported = true;
            }
        }
    }
}

fn play(recent: Recent, difficulty: Option<Difficulty>) -> Play {
    let set = recent.beatmapset;
    // osu! fills the unicode fields for every set, the romanised ones are a guard
    let original =
        |unicode: String, roman: String| if unicode.is_empty() { roman } else { unicode };
    Play {
        played: recent.ended_at,
        map: Map {
            title: original(set.title_unicode, set.title),
            artist: original(set.artist_unicode, set.artist),
            lang: set.language_id.and_then(lang),
            difficulty: recent.beatmap.version,
            stars: difficulty
                .as_ref()
                .map_or(recent.beatmap.difficulty_rating, |d| d.star_rating),
            combo: difficulty.and_then(|d| d.max_combo),
            url: recent.beatmap.url,
            artwork: set.covers.list,
        },
        score: Score {
            rank: recent.rank,
            accuracy: recent.accuracy,
            pp: recent.pp,
            mods: recent.mods.into_iter().map(|m| m.acronym).collect(),
            combo: recent.max_combo,
            perfect: recent.is_perfect_combo,
            misses: recent.statistics.miss,
        },
    }
}
