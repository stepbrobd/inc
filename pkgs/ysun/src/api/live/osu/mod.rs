//! the last osu! pass, polled from the profile's recent scores

mod client;
mod model;
mod poll;

use std::sync::Arc;

use tokio::sync::watch;

use client::Osu;
pub use model::Play;
use poll::Poll;

const CLIENT_ID: &str = "OSU_CLIENT_ID";
const CLIENT_SECRET: &str = "OSU_CLIENT_SECRET";
pub const SECRETS: [&str; 2] = [CLIENT_ID, CLIENT_SECRET];

/// the newest pass, none until a poll succeeds, without a pass in the last day and after the
/// credentials die
pub type Feed = watch::Receiver<Option<Arc<Play>>>;

/// starts the poll, an error when a credential is missing
pub fn start() -> Result<Feed, String> {
    let id = crate::api::secret(CLIENT_ID)?;
    let secret = crate::api::secret(CLIENT_SECRET)?;
    let (publish, feed) = watch::channel(None);
    Poll::new(Osu::new(id, secret), publish)
        .spawn()
        .map_err(|e| format!("starting the osu poll: {e}"))?;
    Ok(feed)
}
