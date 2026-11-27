//! `GET /api/live`: what plays on apple music, or what played last, polled from the listening
//! history and rendered by the browser on every page
//!
//! ```json
//! {
//!   "state": "waiting",
//!   "played": "2026-11-12T10:08:03Z",
//!   "track": {
//!     "title": "絵空事",
//!     "artist": "藍井エイル",
//!     "album": "絵空事 - Single",
//!     "lang": "ja",
//!     "duration": 250484,
//!     "url": "https://music.apple.com/us/album/unrealistic/1882330234?i=1882330235",
//!     "artwork": "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/41/81/00/418100f2-464b-b4a3-0b56-a95668949d9a/4540774748402.jpg/216x216bb.webp"
//!   }
//! }
//! ```
//!
//! - `state` is `playing`, or `waiting` when nothing plays and the track is the last one played
//! - `position`, only while playing, and `duration` are integer milliseconds, position capped at
//!   duration
//! - `played` is when this server saw the play begin, rfc 3339 in utc, absent when the play began
//!   before the server started, since apple's history carries no times
//! - `lang` is the language of title, artist and album, from the storefront they came from
//! - `album`, `duration`, `url` and `artwork` may be absent
//! - 204 with no body when there is nothing to show: no successful poll yet, or dead tokens

mod music;

use std::time::Instant;

use axum::extract::State;
use axum::response::Response;
use axum::routing::{self, MethodRouter};

/// the route with the poll started, an error when a token is missing
pub fn route() -> Result<MethodRouter, String> {
    Ok(routing::get(get).with_state(music::start()?))
}

async fn get(State(feed): State<music::Feed>) -> Response {
    let song = feed.borrow().clone();
    super::json(
        song.as_deref()
            .map(|song| music::Body::new(song, Instant::now())),
    )
}
