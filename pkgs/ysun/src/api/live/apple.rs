use std::collections::HashMap;
use std::fmt;
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use serde::Deserialize;
use serde::de::DeserializeOwned;
use ureq::tls::{RootCerts, TlsConfig};

const API: &str = "https://api.music.apple.com";
const TIMEOUT: Duration = Duration::from_secs(10);
/// apple answers a few percent of calls with an empty 401 that the next call does not repeat
const RETRIES: u32 = 3;
const RETRY_DELAY: Duration = Duration::from_secs(1);

pub enum Failure {
    /// 401 or 403 after the retries
    Auth(u16),
    RateLimit,
    Server(u16),
    Other(String),
}

impl fmt::Display for Failure {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Failure::Auth(status) => write!(f, "apple refused the tokens with {status}"),
            Failure::RateLimit => f.write_str("apple answered 429"),
            Failure::Server(status) => write!(f, "apple answered {status}"),
            Failure::Other(message) => f.write_str(message),
        }
    }
}

#[derive(Deserialize)]
struct Page<T> {
    data: Vec<T>,
}

#[derive(Deserialize)]
struct Resource {
    id: String,
    #[serde(rename = "type")]
    kind: String,
    attributes: Option<Attributes>,
    relationships: Option<Relationships>,
}

#[derive(Deserialize)]
struct Relationships {
    catalog: Option<Page<Resource>>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Attributes {
    pub name: String,
    pub artist_name: String,
    pub album_name: Option<String>,
    pub duration_in_millis: Option<u64>,
    pub url: Option<String>,
    pub artwork: Option<Artwork>,
    pub isrc: Option<String>,
}

#[derive(Deserialize)]
pub struct Artwork {
    pub url: String,
}

#[derive(Deserialize)]
struct Storefront {
    id: String,
    attributes: StorefrontAttributes,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct StorefrontAttributes {
    default_language_tag: String,
}

/// the newest history entry
pub struct Played {
    pub id: String,
    pub catalog: Option<String>,
    /// the catalog song's attributes, or the library song's when there is no catalog song
    pub attributes: Attributes,
}

pub struct Apple {
    agent: ureq::Agent,
    authorization: String,
    user: String,
}

impl Apple {
    pub fn new(developer: &str, user: &str) -> Apple {
        let tls = TlsConfig::builder()
            .root_certs(RootCerts::PlatformVerifier)
            .unversioned_rustls_crypto_provider(Arc::new(rustls::crypto::ring::default_provider()))
            .build();
        let agent = ureq::Agent::config_builder()
            .timeout_global(Some(TIMEOUT))
            .http_status_as_error(false)
            .tls_config(tls)
            .build()
            .into();
        Apple {
            agent,
            authorization: format!("Bearer {developer}"),
            user: user.to_owned(),
        }
    }

    fn get<T: DeserializeOwned>(&self, path: &str) -> Result<T, Failure> {
        let mut attempt = 0;
        loop {
            let mut response = self
                .agent
                .get(format!("{API}{path}"))
                .header("Authorization", &self.authorization)
                .header("Music-User-Token", &self.user)
                .call()
                .map_err(|e| Failure::Other(format!("GET {path}: {e}")))?;
            let status = response.status().as_u16();
            match status {
                200 => {
                    let body = response
                        .body_mut()
                        .read_to_string()
                        .map_err(|e| Failure::Other(format!("GET {path}: {e}")))?;
                    return serde_json::from_str(&body)
                        .map_err(|e| Failure::Other(format!("GET {path}: {e}")));
                }
                401 if attempt < RETRIES => {
                    attempt += 1;
                    thread::sleep(RETRY_DELAY);
                }
                401 | 403 => return Err(Failure::Auth(status)),
                429 => return Err(Failure::RateLimit),
                500..=599 => return Err(Failure::Server(status)),
                _ => return Err(Failure::Other(format!("GET {path}: HTTP {status}"))),
            }
        }
    }

    pub fn recent(&self) -> Result<Option<Played>, Failure> {
        let page: Page<Resource> = self
            .get("/v1/me/recent/played/tracks?types=songs,library-songs&limit=1&include=catalog")?;
        let Some(entry) = page.data.into_iter().next() else {
            return Ok(None);
        };
        let (catalog, attributes) = if entry.kind == "songs" {
            (Some(entry.id.clone()), entry.attributes)
        } else {
            match entry
                .relationships
                .and_then(|r| r.catalog)
                .and_then(|c| c.data.into_iter().next())
                .and_then(|song| Some((song.id, song.attributes?)))
            {
                Some((id, attributes)) => (Some(id), Some(attributes)),
                None => (None, entry.attributes),
            }
        };
        let attributes = attributes.ok_or_else(|| {
            Failure::Other(format!("history entry {} has no attributes", entry.id))
        })?;
        Ok(Some(Played {
            id: entry.id,
            catalog,
            attributes,
        }))
    }

    /// the catalog song in another storefront, none when it is not sold there
    pub fn song(&self, storefront: &str, id: &str) -> Result<Option<Attributes>, Failure> {
        let page: Page<Resource> = self.get(&format!("/v1/catalog/{storefront}/songs?ids={id}"))?;
        Ok(page
            .data
            .into_iter()
            .next()
            .and_then(|song| song.attributes))
    }

    /// every storefront's id and default language
    pub fn storefronts(&self) -> Result<HashMap<String, String>, Failure> {
        let page: Page<Storefront> = self.get("/v1/storefronts?limit=200")?;
        Ok(page
            .data
            .into_iter()
            .map(|s| (s.id, s.attributes.default_language_tag))
            .collect())
    }

    pub fn account(&self) -> Result<String, Failure> {
        let page: Page<Storefront> = self.get("/v1/me/storefront")?;
        page.data
            .into_iter()
            .next()
            .map(|s| s.id)
            .ok_or_else(|| Failure::Other("the account has no storefront".to_owned()))
    }
}
