use std::time::Duration;

use anyhow::{Context, Result};

#[derive(Clone)]
pub struct Settings {
    pub issuer: String,
    pub jwks_uri: String,
    pub audience: String,
    pub required_scope: String,
    pub resource: String,
    pub host: String,
    pub resource_metadata_url: String,
    pub authorization_servers: Vec<String>,
    pub leeway_secs: u64,
    pub jwks_refresh_secs: u64,
    pub default_timeout: Duration,
    pub max_timeout: Duration,
    pub max_output_bytes: usize,
    pub audit_log: Option<String>,
}

impl Settings {
    pub fn from_env() -> Result<Self> {
        let issuer = req_env("MCP_ISSUER")?;
        let jwks_uri =
            std::env::var("MCP_JWKS_URI").unwrap_or_else(|_| format!("{issuer}/public_key.jwk"));
        let resource = req_env("MCP_RESOURCE")?;
        let host = resource
            .parse::<axum::http::Uri>()
            .ok()
            .and_then(|u| u.authority().map(|a| a.to_string()))
            .with_context(|| format!("MCP_RESOURCE {resource} has no host"))?;
        let resource_metadata_url = std::env::var("MCP_RESOURCE_METADATA_URL")
            .unwrap_or_else(|_| format!("{resource}/.well-known/oauth-protected-resource"));
        Ok(Self {
            audience: std::env::var("MCP_AUDIENCE").unwrap_or_else(|_| issuer_tail(&issuer)),
            authorization_servers: vec![issuer.clone()],
            issuer,
            jwks_uri,
            required_scope: std::env::var("MCP_REQUIRED_SCOPE")
                .unwrap_or_else(|_| "mcp:shell".to_string()),
            resource,
            host,
            resource_metadata_url,
            leeway_secs: env_u64("MCP_LEEWAY_SECS", 60),
            jwks_refresh_secs: env_u64("MCP_JWKS_REFRESH_SECS", 3600),
            default_timeout: Duration::from_secs(env_u64("MCP_DEFAULT_TIMEOUT_SECS", 60)),
            max_timeout: Duration::from_secs(env_u64("MCP_MAX_TIMEOUT_SECS", 200)),
            max_output_bytes: env_u64("MCP_MAX_OUTPUT_BYTES", 100_000) as usize,
            audit_log: std::env::var("MCP_AUDIT_LOG").ok(),
        })
    }
}

fn req_env(key: &str) -> Result<String> {
    std::env::var(key).with_context(|| format!("{key} must be set"))
}

fn env_u64(key: &str, default: u64) -> u64 {
    std::env::var(key)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}

// last path segment of the issuer, which kanidm uses as the client_id and the
// token audience
fn issuer_tail(issuer: &str) -> String {
    issuer
        .trim_end_matches('/')
        .rsplit('/')
        .next()
        .unwrap_or("")
        .to_string()
}
