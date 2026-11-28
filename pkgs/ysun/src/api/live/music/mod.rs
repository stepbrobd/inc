//! the song on apple music, polled from the listening history

mod apple;
mod model;
mod poll;

use std::sync::Arc;
use std::time::Instant;

use jiff::Timestamp;
use serde::Serialize;
use tokio::sync::watch;

use apple::Apple;
use model::{Snapshot, State, Track};
use poll::Poll;

const DEVELOPER_TOKEN: &str = "APPLE_MUSIC_DEVELOPER_TOKEN";
const USER_TOKEN: &str = "APPLE_MUSIC_USER_TOKEN";
pub const SECRETS: [&str; 2] = [DEVELOPER_TOKEN, USER_TOKEN];

/// the newest snapshot, none until a poll succeeds and after the tokens die
pub type Feed = watch::Receiver<Option<Arc<Snapshot>>>;

/// starts the poll, an error when a token is missing
pub fn start() -> Result<Feed, String> {
    let developer = crate::api::secret(DEVELOPER_TOKEN)?;
    let user = crate::api::secret(USER_TOKEN)?;
    let (publish, feed) = watch::channel(None);
    Poll::new(Apple::new(&developer, &user), publish)
        .spawn()
        .map_err(|e| format!("starting the music poll: {e}"))?;
    Ok(feed)
}

/// a snapshot as the response shows it, with the state at the request
#[derive(Serialize)]
pub struct Body<'a> {
    #[serde(flatten)]
    state: State,
    #[serde(skip_serializing_if = "Option::is_none")]
    played: Option<Timestamp>,
    track: &'a Track,
}

impl Body<'_> {
    pub fn new(snapshot: &Snapshot, now: Instant) -> Body<'_> {
        Body {
            state: snapshot.state(now),
            played: snapshot.played,
            track: &snapshot.track,
        }
    }
}
