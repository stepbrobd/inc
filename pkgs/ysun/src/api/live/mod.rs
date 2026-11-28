//! `GET /api/live`: what plays on apple music, or what played last, and the last osu! pass, each
//! polled on its own and rendered by the browser on every page
//!
//! ```json
//! {
//!   "music": {
//!     "state": "waiting",
//!     "played": "2026-11-12T10:08:03Z",
//!     "track": {
//!       "title": "絵空事",
//!       "artist": "藍井エイル",
//!       "album": "絵空事 - Single",
//!       "lang": "ja",
//!       "duration": 250484,
//!       "url": "https://music.apple.com/us/album/unrealistic/1882330234?i=1882330235",
//!       "artwork": "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/41/81/00/418100f2-464b-b4a3-0b56-a95668949d9a/4540774748402.jpg/216x216bb.webp"
//!     }
//!   },
//!   "osu": {
//!     "played": "2026-11-27T19:28:50Z",
//!     "map": {
//!       "title": "ユラリユレル (TV Size)",
//!       "artist": "NOMELON NOLEMON",
//!       "lang": "ja",
//!       "difficulty": "Insane",
//!       "stars": 4.949429988861084,
//!       "combo": 447,
//!       "url": "https://osu.ppy.sh/beatmaps/5761165",
//!       "artwork": "https://assets.ppy.sh/beatmaps/2583519/covers/list@2x.jpg?1784567036"
//!     },
//!     "score": {
//!       "rank": "A",
//!       "accuracy": 0.928186,
//!       "pp": 65.2418,
//!       "mods": [],
//!       "combo": 100,
//!       "perfect": false,
//!       "misses": 11
//!     }
//!   }
//! }
//! ```
//!
//! `music`:
//!
//! - `state` is `playing`, or `waiting` when nothing plays and the track is the last one played
//! - `position`, only while playing, and `duration` are integer milliseconds, position capped at
//!   duration
//! - `played` is when this server saw the play begin, rfc 3339 in utc, absent when the play began
//!   before the server started, since apple's history carries no times
//! - `lang` is the language of title, artist and album, from the storefront they came from
//! - `album`, `duration`, `url` and `artwork` may be absent
//!
//! `osu`:
//!
//! - `played` is when the play ended, from osu!, rfc 3339 in utc
//! - `title` and `artist` are in their original script, and `lang` is their language when osu! has
//!   one for the set
//! - `stars` and `map.combo` are with the play's mods, `stars` falls back to the rating without
//!   mods and `map.combo` is absent when that lookup fails
//! - `rank` is osu!'s grade, `XH`, `X`, `SH`, `S`, `A`, `B`, `C` or `D`, `accuracy` a fraction, and
//!   `score.combo` the play's longest combo
//! - `lang`, `map.combo`, `artwork` and `pp` may be absent
//!
//! each is absent when it has nothing to show: no successful poll yet, dead credentials, or for
//! osu! no pass within the day it keeps recent scores for, and the answer is 204 with no body when
//! neither has anything

mod music;
mod osu;

use std::time::Instant;

use axum::extract::State;
use axum::response::Response;
use axum::routing::{self, MethodRouter};
use serde::Serialize;

/// every variable the polls read
pub fn secrets() -> impl Iterator<Item = &'static str> {
    music::SECRETS.into_iter().chain(osu::SECRETS)
}

/// the route with both polls started, an error when a secret is missing
pub fn route() -> Result<MethodRouter, String> {
    let feeds = Feeds {
        music: music::start()?,
        osu: osu::start()?,
    };
    Ok(routing::get(get).with_state(feeds))
}

#[derive(Clone)]
struct Feeds {
    music: music::Feed,
    osu: osu::Feed,
}

/// the response, documented above
#[derive(Serialize)]
struct Body<'a> {
    #[serde(skip_serializing_if = "Option::is_none")]
    music: Option<music::Body<'a>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    osu: Option<&'a osu::Play>,
}

async fn get(State(feeds): State<Feeds>) -> Response {
    let song = feeds.music.borrow().clone();
    let play = feeds.osu.borrow().clone();
    let body = Body {
        music: song
            .as_deref()
            .map(|song| music::Body::new(song, Instant::now())),
        osu: play.as_deref(),
    };
    super::json((body.music.is_some() || body.osu.is_some()).then_some(body))
}
