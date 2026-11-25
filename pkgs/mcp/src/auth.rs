// OAuth 2.1 resource server side. every request carries a kanidm-issued RFC
// 9068 access token which is validated locally against kanidm's JWKS.

use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result};
use axum::{
    body::Body,
    extract::State,
    http::{HeaderMap, HeaderValue, Request, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use jsonwebtoken::jwk::JwkSet;
use jsonwebtoken::{Algorithm, DecodingKey, Validation, decode, decode_header};
use serde::Deserialize;
use serde_json::json;

use crate::AppState;

// kanidm stamps this typ on access tokens, per RFC 9068
const ACCESS_TOKEN_TYP: &str = "at+jwt";
// stamped by the auth layer after validation for the tool handler to log
pub const HDR_SUBJECT: &str = "x-mcp-subject";
pub const HDR_SESSION: &str = "x-mcp-session";
const JWKS_FETCH_TIMEOUT: Duration = Duration::from_secs(10);

#[derive(Debug, Deserialize)]
struct Claims {
    sub: String,
    #[serde(default)]
    scope: String,
    #[serde(default)]
    session_id: Option<String>,
}

pub fn fetch_jwks(uri: &str) -> Result<JwkSet> {
    let tls = ureq::tls::TlsConfig::builder()
        .root_certs(ureq::tls::RootCerts::PlatformVerifier)
        .unversioned_rustls_crypto_provider(Arc::new(rustls::crypto::ring::default_provider()))
        .build();
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(JWKS_FETCH_TIMEOUT))
        .tls_config(tls)
        .build()
        .into();
    let body = agent
        .get(uri)
        .call()
        .with_context(|| format!("fetching JWKS from {uri}"))?
        .body_mut()
        .read_to_string()
        .context("reading JWKS body")?;
    serde_json::from_str(&body).context("parsing JWKS")
}

// refresh keys so a kanidm key rotation is picked up without a restart
pub fn spawn_jwks_refresh(state: AppState) {
    tokio::spawn(async move {
        let every = Duration::from_secs(state.settings.jwks_refresh_secs);
        loop {
            tokio::time::sleep(every).await;
            let uri = state.settings.jwks_uri.clone();
            match tokio::task::spawn_blocking(move || fetch_jwks(&uri)).await {
                Ok(Ok(set)) => *state.jwks.write().await = set,
                Ok(Err(e)) => tracing::warn!(error = %e, "JWKS refresh failed"),
                Err(e) => tracing::warn!(error = %e, "JWKS refresh task failed"),
            }
        }
    });
}

// a missing credential is the normal start of the handshake, not an attack, so
// it is reported apart from a token that was presented and failed validation.
enum Deny {
    Missing,
    Invalid,
    InsufficientScope,
}

async fn validate(state: &AppState, auth: Option<&HeaderValue>) -> Result<Claims, Deny> {
    let raw = auth.and_then(|v| v.to_str().ok()).ok_or(Deny::Missing)?;
    let token = raw.strip_prefix("Bearer ").ok_or(Deny::Invalid)?;

    let header = decode_header(token).map_err(|_| Deny::Invalid)?;
    if header.alg != Algorithm::ES256 {
        return Err(Deny::Invalid);
    }
    if header.typ.as_deref() != Some(ACCESS_TOKEN_TYP) {
        return Err(Deny::Invalid);
    }
    let kid = header.kid.ok_or(Deny::Invalid)?;

    let key = {
        let jwks = state.jwks.read().await;
        let jwk = jwks.find(&kid).ok_or(Deny::Invalid)?;
        DecodingKey::from_jwk(jwk).map_err(|_| Deny::Invalid)?
    };

    let s = &state.settings;
    let mut v = Validation::new(Algorithm::ES256);
    v.set_issuer(&[s.issuer.as_str()]);
    v.set_audience(&[s.audience.as_str()]);
    v.set_required_spec_claims(&["exp", "iss", "aud", "sub"]);
    v.leeway = s.leeway_secs;

    let data = decode::<Claims>(token, &key, &v).map_err(|_| Deny::Invalid)?;
    if !data
        .claims
        .scope
        .split_whitespace()
        .any(|sc| sc == s.required_scope)
    {
        return Err(Deny::InsufficientScope);
    }
    Ok(data.claims)
}

fn challenge(state: &AppState, error: Option<&str>) -> HeaderValue {
    let s = &state.settings;
    let mut v = format!(
        "Bearer resource_metadata=\"{}\", scope=\"{}\"",
        s.resource_metadata_url, s.required_scope
    );
    if let Some(e) = error {
        v.push_str(&format!(", error=\"{e}\""));
    }
    HeaderValue::from_str(&v).expect("ascii challenge")
}

pub fn peer(headers: &HeaderMap) -> Option<String> {
    for h in ["x-real-ip", "x-forwarded-for"] {
        if let Some(v) = headers.get(h).and_then(|v| v.to_str().ok()) {
            return Some(v.to_string());
        }
    }
    None
}

pub async fn layer(State(state): State<AppState>, mut req: Request<Body>, next: Next) -> Response {
    let auth = req.headers().get(header::AUTHORIZATION);
    match validate(&state, auth).await {
        Ok(claims) => {
            if let Ok(v) = HeaderValue::from_str(&claims.sub) {
                req.headers_mut().insert(HDR_SUBJECT, v);
            }
            if let Some(v) = claims
                .session_id
                .as_deref()
                .and_then(|s| HeaderValue::from_str(s).ok())
            {
                req.headers_mut().insert(HDR_SESSION, v);
            }
            next.run(req).await
        }
        Err(deny) => {
            let addr = peer(req.headers());
            let (status, error, reason) = match deny {
                Deny::Missing => (StatusCode::UNAUTHORIZED, None, "missing"),
                Deny::Invalid => (
                    StatusCode::UNAUTHORIZED,
                    Some("invalid_token"),
                    "invalid_token",
                ),
                Deny::InsufficientScope => (
                    StatusCode::FORBIDDEN,
                    Some("insufficient_scope"),
                    "insufficient_scope",
                ),
            };
            // a presented-but-invalid token is worth a warning, a missing one is the
            // normal handshake and an authenticated scope miss is a real user
            if matches!(deny, Deny::Invalid) {
                tracing::warn!(
                    target: "audit",
                    "auth denied from {} reason=invalid_token path={}",
                    addr.as_deref().unwrap_or("-"),
                    req.uri().path()
                );
            }
            state.audit.record(
                "auth_denied",
                json!({ "reason": reason, "peer": addr, "path": req.uri().path() }),
            );
            (
                status,
                [(header::WWW_AUTHENTICATE, challenge(&state, error))],
            )
                .into_response()
        }
    }
}

pub async fn protected_resource_metadata(State(state): State<AppState>) -> Response {
    let s = &state.settings;
    axum::Json(json!({
        "resource": s.resource,
        "authorization_servers": s.authorization_servers,
        "scopes_supported": [s.required_scope],
        "bearer_methods_supported": ["header"],
    }))
    .into_response()
}
