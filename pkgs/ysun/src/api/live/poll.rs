use std::collections::HashMap;
use std::collections::hash_map::RandomState;
use std::hash::BuildHasher;
use std::io;
use std::panic::{self, AssertUnwindSafe};
use std::process;
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant, SystemTime};

use jiff::Timestamp;
use tokio::sync::watch;

use super::apple::{Apple, Attributes, Failure};
use super::model::{
    DEAD_AFTER, INTERVAL, MAX_INTERVAL, Snapshot, Step, Track, Tracker, artwork, delay, origin,
    wall,
};

/// storefront ids with their default language, and the account's storefront
struct Storefronts {
    languages: HashMap<String, String>,
    account: String,
}

pub struct Poll {
    apple: Apple,
    publish: watch::Sender<Option<Arc<Snapshot>>>,
    offset: Duration,
    tracker: Tracker,
    storefronts: Option<Storefronts>,
    interval: Duration,
    /// a failure streak was already reported
    reported: bool,
}

impl Poll {
    pub fn new(apple: Apple, publish: watch::Sender<Option<Arc<Snapshot>>>) -> Poll {
        // a random offset keeps the hosts from calling apple at the same moment
        let offset =
            Duration::from_millis(RandomState::new().hash_one(()) % INTERVAL.as_millis() as u64);
        Poll {
            apple,
            publish,
            offset,
            tracker: Tracker::default(),
            storefronts: None,
            interval: INTERVAL,
            reported: false,
        }
    }

    /// runs the poll on a thread of its own for the life of the process, and a panic there exits the
    /// process, since a dead poll would leave a stale track behind
    pub fn spawn(self) -> io::Result<()> {
        thread::Builder::new()
            .name("live".to_owned())
            .spawn(move || {
                // the panic hook has already printed the panic
                let _ = panic::catch_unwind(AssertUnwindSafe(|| self.run()));
                process::exit(1);
            })
            .map(drop)
    }

    /// the first tick runs at once, so a restart answers 204 only for as long as that tick takes
    fn run(mut self) -> ! {
        loop {
            self.tick(Instant::now());
            thread::sleep(delay(SystemTime::now(), self.offset, self.interval));
        }
    }

    fn tick(&mut self, now: Instant) {
        let result = self.load().and_then(|()| self.apple.recent());
        match result {
            Ok(head) => {
                self.interval = INTERVAL;
                self.reported = false;
                let step = self
                    .tracker
                    .success(now, head.as_ref().map(|h| h.id.as_str()));
                if let (Step::New { start }, Some(head)) = (step, head) {
                    let track = self.resolve(head.catalog, head.attributes);
                    let played = start.map(|start| wall(start, Instant::now(), Timestamp::now()));
                    self.publish.send_replace(Some(Arc::new(Snapshot {
                        track,
                        start,
                        played,
                    })));
                }
            }
            Err(failure) => {
                if matches!(failure, Failure::RateLimit | Failure::Server(_)) {
                    self.interval = (self.interval * 2).min(MAX_INTERVAL);
                }
                if self
                    .tracker
                    .failure(now, matches!(failure, Failure::Auth(_)))
                {
                    eprintln!(
                        "live: {failure} {} minutes after the last success, clearing the track until a poll succeeds",
                        DEAD_AFTER.as_secs() / 60
                    );
                    self.publish.send_replace(None);
                } else if !self.reported {
                    eprintln!("live: {failure}, keeping the last track");
                }
                self.reported = true;
            }
        }
    }

    fn load(&mut self) -> Result<(), Failure> {
        if self.storefronts.is_none() {
            let languages = self.apple.storefronts()?;
            let account = self.apple.account()?;
            if !languages.contains_key(&account) {
                return Err(Failure::Other(format!(
                    "the account's storefront {account} is not among apple's storefronts"
                )));
            }
            self.storefronts = Some(Storefronts { languages, account });
        }
        Ok(())
    }

    fn resolve(&self, catalog: Option<String>, mut attributes: Attributes) -> Track {
        let storefronts = self
            .storefronts
            .as_ref()
            .expect("loaded before the history call");
        // the song in the storefront of its isrc's country, when that is not the account's
        let native = catalog
            .as_deref()
            .zip(attributes.isrc.as_deref())
            .and_then(|(id, isrc)| {
                let store = origin(isrc, &storefronts.account, &storefronts.languages)?;
                match self.apple.song(store, id) {
                    Ok(song) => song.map(|song| (song, store)),
                    Err(failure) => {
                        eprintln!(
                            "live: {failure} looking up {id} in {store}, showing the account's metadata"
                        );
                        None
                    }
                }
            });
        let duration = attributes.duration_in_millis.filter(|&millis| millis > 0);
        let url = catalog.and(attributes.url.take());
        let artwork = attributes.artwork.as_ref().map(|a| artwork(&a.url));
        let (text, store) = native.unwrap_or((attributes, storefronts.account.as_str()));
        Track {
            title: text.name,
            artist: text.artist_name,
            album: text.album_name.filter(|album| !album.is_empty()),
            lang: storefronts.languages[store].clone(),
            duration,
            url,
            artwork,
        }
    }
}
