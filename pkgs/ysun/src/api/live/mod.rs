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
//!     "artwork": "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/41/81/00/418100f2-464b-b4a3-0b56-a95668949d9a/4540774748402.jpg/216x216bb.jpg"
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

mod apple;
mod model;
mod poll;

use std::env;
use std::sync::Arc;
use std::time::Instant;

use axum::extract::State;
use axum::http::StatusCode;
use axum::http::header::{ACCESS_CONTROL_ALLOW_ORIGIN, CACHE_CONTROL, CONTENT_TYPE};
use axum::response::{IntoResponse, Response};
use axum::routing::{self, MethodRouter};
use jiff::Timestamp;
use serde::Serialize;
use tokio::sync::watch;

use apple::Apple;
use model::{Snapshot, Track};
use poll::Poll;

const DEVELOPER_TOKEN: &str = "APPLE_MUSIC_DEVELOPER_TOKEN";
const USER_TOKEN: &str = "APPLE_MUSIC_USER_TOKEN";

/// the newest snapshot, none until a poll succeeds and after the tokens die
type Feed = watch::Receiver<Option<Arc<Snapshot>>>;

/// the route's handlers with the poll they read from, an error when a token is missing
pub fn route() -> Result<MethodRouter, String> {
    Ok(routing::get(get).with_state(start()?))
}

/// starts the poll, the hosts get both tokens from sops-nix and the devshell from `.envrc`
fn start() -> Result<Feed, String> {
    let token = |name| match env::var(name) {
        Ok(value) if !value.trim().is_empty() => Ok(value.trim().to_owned()),
        _ => Err(format!("{name} must be set, valid utf-8 and not empty")),
    };
    let (developer, user) = (token(DEVELOPER_TOKEN)?, token(USER_TOKEN)?);
    let (publish, feed) = watch::channel(None);
    Poll::new(Apple::new(&developer, &user), publish)
        .spawn()
        .map_err(|e| format!("starting the live poll: {e}"))?;
    Ok(feed)
}

/// the response, documented above
#[derive(Serialize)]
struct Body<'a> {
    #[serde(flatten)]
    state: model::State,
    #[serde(skip_serializing_if = "Option::is_none")]
    played: Option<Timestamp>,
    track: &'a Track,
}

async fn get(State(feed): State<Feed>) -> Response {
    let headers = [
        (CACHE_CONTROL, "no-store"),
        (ACCESS_CONTROL_ALLOW_ORIGIN, "*"),
    ];
    let snapshot = feed.borrow().clone();
    match snapshot {
        Some(snapshot) => {
            let body = Body {
                state: snapshot.state(Instant::now()),
                played: snapshot.played,
                track: &snapshot.track,
            };
            let json = serde_json::to_string(&body).expect("strings and numbers serialize");
            (headers, [(CONTENT_TYPE, "application/json")], json).into_response()
        }
        None => (StatusCode::NO_CONTENT, headers).into_response(),
    }
}
