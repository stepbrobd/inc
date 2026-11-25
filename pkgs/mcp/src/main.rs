// a resource-server MCP shell. it exposes tools that execute commands as the
// service user. every request carries a kanidm-issued RFC 9068 access token
// which this process validates locally against kanidm's JWKS before any tool
// runs. it is the OAuth 2.1 resource server only, never the authorization
// server.

use std::os::fd::FromRawFd;
use std::sync::Arc;

use anyhow::{Context, Result};
use axum::routing::get;
use jsonwebtoken::jwk::JwkSet;
use rmcp::transport::streamable_http_server::session::local::LocalSessionManager;
use rmcp::transport::streamable_http_server::{StreamableHttpServerConfig, StreamableHttpService};
use serde_json::json;
use tokio::sync::RwLock;
use tower::ServiceBuilder;

mod audit;
mod auth;
mod config;
mod exec;
mod prompts;
mod target;
mod tools;

use audit::Audit;
use config::Settings;

#[derive(Clone)]
pub struct AppState {
    settings: Arc<Settings>,
    jwks: Arc<RwLock<JwkSet>>,
    audit: Arc<Audit>,
}

enum Listener {
    Tcp(tokio::net::TcpListener),
    Unix(tokio::net::UnixListener),
}

// systemd socket activation passes a unix socket as fd 3. for local testing,
// MCP_LISTEN is tcp:addr or unix:path.
async fn listener() -> Result<Listener> {
    let fds = std::env::var("LISTEN_FDS")
        .ok()
        .and_then(|v| v.parse::<i32>().ok())
        .unwrap_or(0);
    let for_us = std::env::var("LISTEN_PID")
        .ok()
        .and_then(|v| v.parse::<u32>().ok())
        .map(|p| p == std::process::id())
        .unwrap_or(false);
    if for_us && fds >= 1 {
        // systemd passes the first socket as fd 3
        let std = unsafe { std::os::unix::net::UnixListener::from_raw_fd(3) };
        std.set_nonblocking(true)?;
        return Ok(Listener::Unix(tokio::net::UnixListener::from_std(std)?));
    }
    match std::env::var("MCP_LISTEN") {
        Ok(spec) if spec.starts_with("unix:") => {
            Ok(Listener::Unix(tokio::net::UnixListener::bind(&spec[5..])?))
        }
        Ok(spec) if spec.starts_with("tcp:") => Ok(Listener::Tcp(
            tokio::net::TcpListener::bind(&spec[4..]).await?,
        )),
        _ => anyhow::bail!("no systemd socket and MCP_LISTEN unset"),
    }
}

async fn shutdown() {
    let mut term =
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()).unwrap();
    tokio::select! {
        _ = tokio::signal::ctrl_c() => {}
        _ = term.recv() => {}
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let settings = Arc::new(Settings::from_env()?);
    let audit = Arc::new(Audit::new(settings.audit_log.as_deref())?);
    let jwks = auth::fetch_jwks(&settings.jwks_uri)?;
    let state = AppState {
        settings: settings.clone(),
        jwks: Arc::new(RwLock::new(jwks)),
        audit: audit.clone(),
    };
    audit.record(
        "startup",
        json!({ "issuer": settings.issuer, "resource": settings.resource }),
    );
    auth::spawn_jwks_refresh(state.clone());
    // children start in the service user's home unless a call names a cwd
    std::env::set_current_dir(&settings.home)
        .with_context(|| format!("entering HOME {}", settings.home))?;
    let hostname: Arc<str> = nix::unistd::gethostname()
        .context("gethostname")?
        .to_string_lossy()
        .into();

    let mcp = StreamableHttpService::new(
        {
            let settings = settings.clone();
            let audit = audit.clone();
            move || {
                Ok(tools::Shell::new(
                    settings.clone(),
                    audit.clone(),
                    hostname.clone(),
                ))
            }
        },
        LocalSessionManager::default().into(),
        StreamableHttpServerConfig::default().with_allowed_hosts([settings.host.clone()]),
    );
    let guarded = ServiceBuilder::new()
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            auth::layer,
        ))
        .service(mcp);

    let router = axum::Router::new()
        .route(
            "/.well-known/oauth-protected-resource",
            get(auth::protected_resource_metadata),
        )
        .route(
            "/.well-known/oauth-protected-resource/mcp",
            get(auth::protected_resource_metadata),
        )
        .nest_service("/mcp", guarded)
        .with_state(state);

    match listener().await? {
        Listener::Tcp(l) => {
            axum::serve(l, router)
                .with_graceful_shutdown(shutdown())
                .await?
        }
        Listener::Unix(l) => {
            axum::serve(l, router)
                .with_graceful_shutdown(shutdown())
                .await?
        }
    }
    Ok(())
}
