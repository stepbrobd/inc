// a resource-server MCP shell. it exposes one tool, `run`, that executes a
// command line under a configured shell as the service user. every request
// carries a kanidm-issued RFC 9068 access token which this process validates
// locally against kanidm's JWKS before any tool runs. it is the OAuth 2.1
// resource server only, never the authorization server.

use std::os::fd::FromRawFd;
use std::process::Stdio;
use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use axum::{
    body::Body,
    extract::State,
    http::{HeaderValue, Request, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
    routing::get,
};
use jsonwebtoken::jwk::JwkSet;
use jsonwebtoken::{Algorithm, DecodingKey, Validation, decode, decode_header};
use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::{CallToolResult, ContentBlock, Implementation, ServerCapabilities, ServerConfig};
use rmcp::service::RequestContext;
use rmcp::transport::streamable_http_server::session::local::LocalSessionManager;
use rmcp::transport::streamable_http_server::{StreamableHttpServerConfig, StreamableHttpService};
use rmcp::{ErrorData, RoleServer, ServerHandler, tool, tool_handler, tool_router};
use serde::Deserialize;
use serde_json::json;
use tokio::io::AsyncReadExt;
use tokio::sync::RwLock;
use tower::ServiceBuilder;

mod audit;
mod prompts;
use audit::Audit;

// kanidm stamps this typ on access tokens, per RFC 9068
const ACCESS_TOKEN_TYP: &str = "at+jwt";
const PIPE_CHUNK: usize = 8192;
// shell used when the caller passes none; a full path is expected
const DEFAULT_SHELL: &str = "/bin/sh";
// stamped by the auth layer after validation for the tool handler to log
const HDR_SUBJECT: &str = "x-mcp-subject";
const HDR_SESSION: &str = "x-mcp-session";
const JWKS_FETCH_TIMEOUT: Duration = Duration::from_secs(10);

#[derive(Clone)]
struct Settings {
    issuer: String,
    jwks_uri: String,
    audience: String,
    required_scope: String,
    resource: String,
    resource_metadata_url: String,
    authorization_servers: Vec<String>,
    leeway_secs: u64,
    jwks_refresh_secs: u64,
    default_timeout: Duration,
    max_timeout: Duration,
    max_output_bytes: usize,
    audit_log: Option<String>,
}

impl Settings {
    fn from_env() -> Result<Self> {
        let issuer = req_env("MCP_ISSUER")?;
        let jwks_uri =
            std::env::var("MCP_JWKS_URI").unwrap_or_else(|_| format!("{issuer}/public_key.jwk"));
        let resource = req_env("MCP_RESOURCE")?;
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

#[derive(Clone)]
struct AppState {
    settings: Arc<Settings>,
    jwks: Arc<RwLock<JwkSet>>,
    audit: Arc<Audit>,
}

#[derive(Debug, Deserialize)]
struct Claims {
    sub: String,
    #[serde(default)]
    scope: String,
    #[serde(default)]
    session_id: Option<String>,
}

fn fetch_jwks(uri: &str) -> Result<JwkSet> {
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(JWKS_FETCH_TIMEOUT))
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

fn peer(req: &Request<Body>) -> Option<String> {
    for h in ["x-real-ip", "x-forwarded-for"] {
        if let Some(v) = req.headers().get(h).and_then(|v| v.to_str().ok()) {
            return Some(v.to_string());
        }
    }
    None
}

async fn auth_layer(State(state): State<AppState>, mut req: Request<Body>, next: Next) -> Response {
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
            let addr = peer(&req);
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
            // a presented-but-invalid token is the fail2ban signal; a missing one
            // is the normal handshake and an authenticated scope miss is a real user
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

async fn protected_resource_metadata(State(state): State<AppState>) -> Response {
    let s = &state.settings;
    axum::Json(json!({
        "resource": s.resource,
        "authorization_servers": s.authorization_servers,
        "scopes_supported": [s.required_scope],
        "bearer_methods_supported": ["header"],
    }))
    .into_response()
}

#[derive(Debug, Deserialize, schemars::JsonSchema)]
struct RunArgs {
    /// command line passed to the shell with -c
    command: String,
    /// absolute path to the shell, default /bin/sh. to use bash, fish, nushell,
    /// etc, resolve its full path first (request it in `packages` and run
    /// `command -v <shell>`), then pass that path here.
    #[serde(default)]
    shell: Option<String>,
    /// nixpkgs attribute names to put on PATH for this call via `nix shell`,
    /// e.g. ["tmux", "ripgrep"] runs under `nix shell nixpkgs#tmux nixpkgs#ripgrep`.
    #[serde(default)]
    packages: Vec<String>,
    /// working directory, defaults to the service user's home
    #[serde(default)]
    cwd: Option<String>,
    /// wall-clock timeout in seconds, capped by the server
    #[serde(default)]
    timeout_secs: Option<u64>,
}

#[derive(Clone)]
struct Shell {
    settings: Arc<Settings>,
    audit: Arc<Audit>,
}

#[tool_router]
impl Shell {
    fn new(settings: Arc<Settings>, audit: Arc<Audit>) -> Self {
        Self { settings, audit }
    }

    #[tool(description = prompts::RUN_TOOL)]
    async fn run(
        &self,
        Parameters(args): Parameters<RunArgs>,
        ctx: RequestContext<RoleServer>,
    ) -> Result<CallToolResult, ErrorData> {
        let s = &self.settings;
        let (subject, session) = caller(&ctx);
        let timeout = args
            .timeout_secs
            .map(Duration::from_secs)
            .unwrap_or(s.default_timeout)
            .min(s.max_timeout);
        let home = std::env::var("HOME").unwrap_or_else(|_| "/".to_string());
        let cwd = args.cwd.clone().unwrap_or(home);
        let shell = args.shell.as_deref().unwrap_or(DEFAULT_SHELL);

        let call = self.audit.next_call();
        self.audit.record(
            "run_start",
            json!({
                "call": call, "subject": subject, "session": session,
                "command": args.command, "shell": shell, "packages": args.packages,
                "cwd": cwd, "timeout_s": timeout.as_secs(),
            }),
        );

        let started = Instant::now();
        let outcome = execute(
            shell,
            &args.packages,
            &args.command,
            &cwd,
            timeout,
            s.max_output_bytes,
        )
        .await;
        let elapsed = started.elapsed();

        match outcome {
            Ok(r) => {
                self.audit.record(
                    "run_end",
                    json!({
                        "call": call, "subject": subject,
                        "exit": r.exit, "timed_out": r.timed_out, "truncated": r.truncated,
                        "bytes": r.body.len(), "ms": elapsed.as_millis() as u64,
                    }),
                );
                let mut head = format!(
                    "exit: {}\nduration: {:.2}s",
                    r.exit
                        .map(|c| c.to_string())
                        .unwrap_or_else(|| "signal".to_string()),
                    elapsed.as_secs_f64()
                );
                if r.timed_out {
                    head.push_str(&format!("\ntimed out after {}s, killed", timeout.as_secs()));
                }
                if r.truncated {
                    head.push_str(&format!(
                        "\noutput truncated to {} bytes",
                        s.max_output_bytes
                    ));
                }
                Ok(CallToolResult::success(vec![ContentBlock::text(format!(
                    "{head}\n\n{}",
                    r.body
                ))]))
            }
            Err(e) => {
                self.audit.record(
                    "run_error",
                    json!({ "call": call, "subject": subject, "error": e.to_string() }),
                );
                Err(ErrorData::internal_error(
                    format!("spawn failed: {e}"),
                    None,
                ))
            }
        }
    }
}

#[tool_handler]
impl ServerHandler for Shell {
    fn get_info(&self) -> ServerConfig {
        ServerConfig::new(ServerCapabilities::builder().enable_tools().build())
            .with_server_info(Implementation::from_build_env())
            .with_instructions(prompts::SERVER_INSTRUCTIONS.to_string())
    }
}

fn caller(ctx: &RequestContext<RoleServer>) -> (String, Option<String>) {
    let parts = ctx.extensions.get::<axum::http::request::Parts>();
    let get = |name: &str| {
        parts
            .and_then(|p| p.headers.get(name))
            .and_then(|v| v.to_str().ok())
            .map(|s| s.to_string())
    };
    (
        get(HDR_SUBJECT).unwrap_or_else(|| "unknown".to_string()),
        get(HDR_SESSION),
    )
}

struct RunResult {
    body: String,
    exit: Option<i32>,
    timed_out: bool,
    truncated: bool,
}

async fn execute(
    shell: &str,
    packages: &[String],
    command: &str,
    cwd: &str,
    timeout: Duration,
    cap: usize,
) -> Result<RunResult> {
    // with no extra packages run the shell directly; otherwise wrap it in
    // `nix shell nixpkgs#<pkg> ... --command <shell> -c <command>` so the call
    // sees those packages on PATH. argv is passed literally, never through a shell.
    let mut cmd = if packages.is_empty() {
        let mut c = tokio::process::Command::new(shell);
        c.arg("-c").arg(command);
        c
    } else {
        let mut c = tokio::process::Command::new("nix");
        c.arg("shell");
        for p in packages {
            c.arg(format!("nixpkgs#{p}"));
        }
        c.arg("--command").arg(shell).arg("-c").arg(command);
        c
    };
    cmd.current_dir(cwd)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true);
    // own process group so a timeout kills the whole subtree, not just the shell
    cmd.process_group(0);

    let mut child = cmd.spawn().context("spawn")?;
    let pid = child.id().context("child pid")? as i32;

    let out = child.stdout.take().expect("piped");
    let err = child.stderr.take().expect("piped");
    let out_task = tokio::spawn(drain(out, cap));
    let err_task = tokio::spawn(drain(err, cap));

    let timed_out = tokio::time::timeout(timeout, child.wait()).await.is_err();
    if timed_out {
        // kill the whole group, not just the shell. the child is the group
        // leader, so its pid is the pgid. nix wraps killpg(2) safely.
        let _ = nix::sys::signal::killpg(
            nix::unistd::Pid::from_raw(pid),
            nix::sys::signal::Signal::SIGKILL,
        );
    }
    let status = child.wait().await.context("wait")?;
    let (o, o_cut) = out_task.await.unwrap_or_default();
    let (e, e_cut) = err_task.await.unwrap_or_default();

    let mut body = String::from_utf8_lossy(&o).into_owned();
    if !e.is_empty() {
        body.push_str("\n--- stderr ---\n");
        body.push_str(&String::from_utf8_lossy(&e));
    }

    Ok(RunResult {
        body,
        exit: status.code(),
        timed_out,
        truncated: o_cut || e_cut,
    })
}

// read a pipe to EOF, keeping at most `cap` bytes but still draining the rest so
// the child never blocks on a full pipe. returns the kept bytes and whether more
// were discarded.
async fn drain<R: AsyncReadExt + Unpin>(mut r: R, cap: usize) -> (Vec<u8>, bool) {
    let mut kept = Vec::new();
    let mut truncated = false;
    let mut buf = [0u8; PIPE_CHUNK];
    loop {
        match r.read(&mut buf).await {
            Ok(0) | Err(_) => break,
            Ok(n) => {
                if kept.len() < cap {
                    let take = n.min(cap - kept.len());
                    kept.extend_from_slice(&buf[..take]);
                    truncated |= take < n;
                } else {
                    truncated = true;
                }
            }
        }
    }
    (kept, truncated)
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
    let jwks = fetch_jwks(&settings.jwks_uri)?;
    let state = AppState {
        settings: settings.clone(),
        jwks: Arc::new(RwLock::new(jwks)),
        audit: audit.clone(),
    };
    audit.record(
        "startup",
        json!({ "issuer": settings.issuer, "resource": settings.resource }),
    );

    // refresh keys so a kanidm key rotation is picked up without a restart
    {
        let state = state.clone();
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

    let mcp = StreamableHttpService::new(
        {
            let settings = settings.clone();
            let audit = audit.clone();
            move || Ok(Shell::new(settings.clone(), audit.clone()))
        },
        LocalSessionManager::default().into(),
        StreamableHttpServerConfig::default(),
    );
    let guarded = ServiceBuilder::new()
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            auth_layer,
        ))
        .service(mcp);

    let router = axum::Router::new()
        .route(
            "/.well-known/oauth-protected-resource",
            get(protected_resource_metadata),
        )
        .route(
            "/.well-known/oauth-protected-resource/mcp",
            get(protected_resource_metadata),
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
