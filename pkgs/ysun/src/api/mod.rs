//! the routes under API, which the server answers itself and build.rs keeps the static site out of

mod live;

use std::env;
use std::sync::Arc;
use std::time::Duration;

use axum::Router;
use axum::http::StatusCode;
use axum::http::header::{ACCESS_CONTROL_ALLOW_ORIGIN, CACHE_CONTROL, CONTENT_TYPE};
use axum::response::{IntoResponse, Response};
use serde::Serialize;
use ureq::tls::{RootCerts, TlsConfig};

/// per call, so a stalled upstream holds a poll this long at most
const TIMEOUT: Duration = Duration::from_secs(10);

/// the routes relative to API, for nesting under it, with what they serve from started, an unknown
/// path falls through to the site's fallback, which answers everything under API with a bare 404
pub fn router() -> Result<Router, String> {
    Ok(Router::new().route("/live", live::route()?))
}

/// a secret from the environment, the hosts get them from sops-nix and the devshell from `.envrc`
fn secret(name: &str) -> Result<String, String> {
    match env::var(name) {
        Ok(value) if !value.trim().is_empty() => Ok(value.trim().to_owned()),
        _ => Err(format!("{name} must be set, valid utf-8 and not empty")),
    }
}

/// the polls' http client, verifying against the platform's roots and leaving statuses to the caller
fn agent() -> ureq::Agent {
    let tls = TlsConfig::builder()
        .root_certs(RootCerts::PlatformVerifier)
        .unversioned_rustls_crypto_provider(Arc::new(rustls::crypto::ring::default_provider()))
        .build();
    ureq::Agent::config_builder()
        .timeout_global(Some(TIMEOUT))
        .http_status_as_error(false)
        .tls_config(tls)
        .build()
        .into()
}

/// what a poll last published, or 204 when there is nothing to show
fn json(body: Option<impl Serialize>) -> Response {
    let headers = [
        (CACHE_CONTROL, "no-store"),
        (ACCESS_CONTROL_ALLOW_ORIGIN, "*"),
    ];
    match body {
        Some(body) => {
            let json = serde_json::to_string(&body).expect("strings and numbers serialize");
            (headers, [(CONTENT_TYPE, "application/json")], json).into_response()
        }
        None => (StatusCode::NO_CONTENT, headers).into_response(),
    }
}
