use std::fmt;
use std::time::{Duration, Instant};

use jiff::Timestamp;
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use ureq::Body;
use ureq::http::Response;

const SITE: &str = "https://osu.ppy.sh";
/// the score format with mods as objects and the play's start and end
const VERSION: &str = "20220705";
/// a token is renewed this long before osu! says it expires
const MARGIN: Duration = Duration::from_secs(300);

pub enum Failure {
    /// 401 or 403, after one fresh token for an api call
    Auth(u16),
    Other(String),
}

impl fmt::Display for Failure {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Failure::Auth(status) => write!(f, "osu! refused the credentials with {status}"),
            Failure::Other(message) => f.write_str(message),
        }
    }
}

#[derive(Deserialize)]
struct Token {
    access_token: String,
    expires_in: u64,
}

#[derive(Deserialize)]
pub struct Recent {
    pub id: u64,
    pub ended_at: Timestamp,
    pub rank: String,
    pub accuracy: f64,
    pub pp: Option<f64>,
    pub mods: Vec<Mod>,
    pub max_combo: u32,
    pub is_perfect_combo: bool,
    pub statistics: Statistics,
    pub ruleset_id: u8,
    pub beatmap: Beatmap,
    pub beatmapset: Beatmapset,
}

/// sent back as it came for the attributes call, since settings such as a custom rate change the
/// rating
#[derive(Deserialize, Serialize)]
pub struct Mod {
    pub acronym: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub settings: Option<serde_json::Value>,
}

#[derive(Deserialize)]
pub struct Statistics {
    #[serde(default)]
    pub miss: u32,
}

#[derive(Deserialize)]
pub struct Beatmap {
    pub id: u64,
    pub version: String,
    /// without mods
    pub difficulty_rating: f64,
    pub url: String,
}

#[derive(Deserialize)]
pub struct Beatmapset {
    pub title: String,
    pub title_unicode: String,
    pub artist: String,
    pub artist_unicode: String,
    pub language_id: Option<u32>,
    pub covers: Covers,
}

#[derive(Deserialize)]
pub struct Covers {
    /// the square thumbnail at twice its size
    #[serde(rename = "list@2x")]
    pub list: Option<String>,
}

#[derive(Deserialize)]
struct Attributes {
    attributes: Difficulty,
}

#[derive(Deserialize)]
pub struct Difficulty {
    pub star_rating: f64,
    pub max_combo: Option<u32>,
}

pub struct Osu {
    agent: ureq::Agent,
    id: String,
    secret: String,
    /// the bearer token and when to renew it
    token: Option<(String, Instant)>,
}

impl Osu {
    pub fn new(id: String, secret: String) -> Osu {
        Osu {
            agent: crate::api::agent(),
            id,
            secret,
            token: None,
        }
    }

    /// the newest pass of the user within the day osu! keeps recent scores for
    pub fn recent(&mut self, user: u32) -> Result<Option<Recent>, Failure> {
        let scores: Vec<Recent> =
            self.call(&format!("/users/{user}/scores/recent?limit=1"), None)?;
        Ok(scores.into_iter().next())
    }

    /// the map's rating and full combo with the play's mods
    pub fn difficulty(&mut self, play: &Recent) -> Result<Difficulty, Failure> {
        #[derive(Serialize)]
        struct Request<'a> {
            mods: &'a [Mod],
            ruleset_id: u8,
        }
        let body = serde_json::to_string(&Request {
            mods: &play.mods,
            ruleset_id: play.ruleset_id,
        })
        .expect("strings and numbers serialize");
        let attributes: Attributes = self.call(
            &format!("/beatmaps/{}/attributes", play.beatmap.id),
            Some(&body),
        )?;
        Ok(attributes.attributes)
    }

    /// an api call, a GET without a body and a json POST with one, retried once with a new token
    /// when osu! no longer accepts the one held
    fn call<T: DeserializeOwned>(&mut self, path: &str, body: Option<&str>) -> Result<T, Failure> {
        let what = format!("{} {path}", if body.is_some() { "POST" } else { "GET" });
        let mut response = self.send(path, body, &what)?;
        if response.status() == 401 {
            self.token = None;
            response = self.send(path, body, &what)?;
        }
        read(&what, response)
    }

    fn send(
        &mut self,
        path: &str,
        body: Option<&str>,
        what: &str,
    ) -> Result<Response<Body>, Failure> {
        let authorization = format!("Bearer {}", self.token()?);
        let url = format!("{SITE}/api/v2{path}");
        match body {
            Some(body) => self
                .agent
                .post(&url)
                .header("Authorization", &authorization)
                .header("Accept", "application/json")
                .header("Content-Type", "application/json")
                .header("x-api-version", VERSION)
                .send(body),
            None => self
                .agent
                .get(&url)
                .header("Authorization", &authorization)
                .header("Accept", "application/json")
                .header("x-api-version", VERSION)
                .call(),
        }
        .map_err(|e| Failure::Other(format!("{what}: {e}")))
    }

    /// a token from the client credentials grant, held until shortly before it expires
    fn token(&mut self) -> Result<String, Failure> {
        if let Some((token, renew)) = &self.token
            && Instant::now() < *renew
        {
            return Ok(token.clone());
        }
        let what = "POST /oauth/token";
        let response = self
            .agent
            .post(format!("{SITE}/oauth/token"))
            .header("Accept", "application/json")
            .send_form([
                ("client_id", self.id.as_str()),
                ("client_secret", self.secret.as_str()),
                ("grant_type", "client_credentials"),
                ("scope", "public"),
            ])
            .map_err(|e| Failure::Other(format!("{what}: {e}")))?;
        let token: Token = read(what, response)?;
        let lifetime = Duration::from_secs(token.expires_in).saturating_sub(MARGIN);
        self.token = Some((token.access_token.clone(), Instant::now() + lifetime));
        Ok(token.access_token)
    }
}

fn read<T: DeserializeOwned>(what: &str, mut response: Response<Body>) -> Result<T, Failure> {
    let status = response.status().as_u16();
    match status {
        200 => {
            let body = response
                .body_mut()
                .read_to_string()
                .map_err(|e| Failure::Other(format!("{what}: {e}")))?;
            serde_json::from_str(&body).map_err(|e| Failure::Other(format!("{what}: {e}")))
        }
        401 | 403 => Err(Failure::Auth(status)),
        _ => Err(Failure::Other(format!("{what}: HTTP {status}"))),
    }
}
