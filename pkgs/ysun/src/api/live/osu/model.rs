use std::time::Duration;

use jiff::Timestamp;
use serde::Serialize;

/// the profile whose plays are shown, osu.ppy.sh/users/stepbrobd
pub const USER: u32 = 20905967;
/// one poll a minute, the most osu!'s terms allow for one user
pub const INTERVAL: Duration = Duration::from_secs(60);
/// ceiling for the backoff, which doubles the interval on every failure
pub const MAX_INTERVAL: Duration = Duration::from_secs(300);
/// an auth failure this long after the last success means the credentials are dead rather than
/// osu! flaking
pub const DEAD_AFTER: Duration = Duration::from_secs(15 * 60);

/// serialized as the response
#[derive(Serialize)]
pub struct Play {
    /// when the play ended
    pub played: Timestamp,
    pub map: Map,
    pub score: Score,
}

#[derive(Serialize)]
pub struct Map {
    pub title: String,
    pub artist: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lang: Option<&'static str>,
    pub difficulty: String,
    pub stars: f64,
    /// the map's full combo with the play's mods
    #[serde(skip_serializing_if = "Option::is_none")]
    pub combo: Option<u32>,
    pub url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub artwork: Option<String>,
}

#[derive(Serialize)]
pub struct Score {
    pub rank: String,
    pub accuracy: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pp: Option<f64>,
    pub mods: Vec<String>,
    /// the play's longest combo
    pub combo: u32,
    pub perfect: bool,
    pub misses: u32,
}

/// osu-web's beatmapset language ids as bcp 47 tags, none for unspecified, instrumental and other
pub fn lang(id: u32) -> Option<&'static str> {
    Some(match id {
        2 => "en",
        3 => "ja",
        4 => "zh",
        6 => "ko",
        7 => "fr",
        8 => "de",
        9 => "sv",
        10 => "es",
        11 => "it",
        12 => "ru",
        13 => "pl",
        _ => return None,
    })
}
