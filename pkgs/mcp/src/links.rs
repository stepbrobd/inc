// short-lived capability urls that move file bytes between an http client and
// a target, so transfers never pass through the model. a token is 256 random
// bits bound to one direction, target and path, and lives only in memory.

use std::collections::HashMap;
use std::process::Stdio;
use std::sync::{Mutex, MutexGuard};
use std::time::{Duration, Instant};

use anyhow::{Context, Result, bail};
use axum::body::Body;
use axum::extract::{Path, State};
use axum::http::{HeaderMap, HeaderName, HeaderValue, Request, StatusCode, header};
use axum::response::{IntoResponse, Response};
use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use futures_util::TryStreamExt;
use serde_json::json;
use tokio::io::{AsyncBufReadExt, AsyncReadExt, BufReader};
use tokio_util::io::{ReaderStream, StreamReader};

use crate::AppState;
use crate::auth::peer;
use crate::target::Target;

const FILES_SH: &str = include_str!("files.sh");
const UPLOAD_HTML: &str = include_str!("upload.html");
const TOKEN_BYTES: usize = 32;
// covers an ssh connect plus a stat on the far side
const PROBE_TIMEOUT: Duration = Duration::from_secs(30);
// ssh exits with this status when it fails itself, before the remote command
const SSH_FAILED: i32 = 255;

#[derive(Clone, Copy, PartialEq, Debug)]
pub enum Direction {
    Upload,
    Download,
}

impl Direction {
    pub fn as_str(self) -> &'static str {
        match self {
            Direction::Upload => "upload",
            Direction::Download => "download",
        }
    }
}

#[derive(Clone)]
pub struct Grant {
    direction: Direction,
    target: Target,
    path: String,
    call: u64,
    expires: Instant,
}

pub struct Links {
    grants: Mutex<HashMap<String, Grant>>,
    pub ttl: Duration,
}

impl Links {
    pub fn new(ttl: Duration) -> Self {
        Self {
            grants: Mutex::new(HashMap::new()),
            ttl,
        }
    }

    pub fn mint(&self, direction: Direction, target: Target, path: String, call: u64) -> String {
        let mut raw = [0u8; TOKEN_BYTES];
        getrandom::fill(&mut raw).expect("os randomness");
        let token = URL_SAFE_NO_PAD.encode(raw);
        let grant = Grant {
            direction,
            target,
            path,
            call,
            expires: Instant::now() + self.ttl,
        };
        self.live().insert(token.clone(), grant);
        token
    }

    fn get(&self, token: &str) -> Option<Grant> {
        self.live().get(token).cloned()
    }

    // an upload grant is held by one request at a time and spent on success
    fn take_upload(&self, token: &str) -> Option<Grant> {
        let mut live = self.live();
        match live.get(token) {
            Some(g) if g.direction == Direction::Upload => live.remove(token),
            _ => None,
        }
    }

    fn restore(&self, token: String, grant: Grant) {
        if grant.expires > Instant::now() {
            self.live().insert(token, grant);
        }
    }

    fn live(&self) -> MutexGuard<'_, HashMap<String, Grant>> {
        let mut grants = self.grants.lock().unwrap_or_else(|e| e.into_inner());
        let now = Instant::now();
        grants.retain(|_, g| g.expires > now);
        grants
    }
}

fn files_argv(args: &[&str]) -> Vec<String> {
    let mut argv = vec!["/bin/sh", "-c", FILES_SH, "mcp-files"];
    argv.extend_from_slice(args);
    argv.into_iter().map(String::from).collect()
}

// runs a files.sh check before a link is minted, so a bad path fails in the
// tool call rather than in the browser. returns its trimmed stdout
pub async fn probe(target: &Target, verb: &str, path: &str) -> Result<String> {
    let mut cmd = target.command(&files_argv(&[verb, path]), None)?;
    cmd.stdin(Stdio::null()).kill_on_drop(true);
    let out = tokio::time::timeout(PROBE_TIMEOUT, cmd.output())
        .await
        .context("timed out checking the path")?
        .context("spawn")?;
    if !out.status.success() {
        bail!("{}", String::from_utf8_lossy(&out.stderr).trim());
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

pub async fn get(
    State(state): State<AppState>,
    Path(token): Path<String>,
    headers: HeaderMap,
) -> Response {
    let resp = match state.links.get(&token) {
        None => missing(&token),
        Some(g) if g.direction == Direction::Upload => page(&state, &g),
        Some(g) => download(&state, &g, peer(&headers)).await,
    };
    private(resp)
}

pub async fn put(
    State(state): State<AppState>,
    Path(token): Path<String>,
    req: Request<Body>,
) -> Response {
    let Some(grant) = state.links.take_upload(&token) else {
        return private(missing(&token));
    };
    let addr = peer(req.headers());
    let size = req
        .headers()
        .get(header::CONTENT_LENGTH)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok());
    let max = state.settings.max_upload_bytes;
    let outcome = match size {
        None => Err((
            StatusCode::LENGTH_REQUIRED,
            "Send the file with a Content-Length header.".to_string(),
        )),
        Some(n) if n > max => Err((
            StatusCode::PAYLOAD_TOO_LARGE,
            format!("The file is {n} bytes, the limit is {max}."),
        )),
        Some(n) => upload(&grant, n, req.into_body()).await.map(|()| n),
    };
    state.audit.record(
        "link_use",
        json!({
            "call": grant.call, "direction": "upload", "host": grant.target.host(),
            "path": grant.path, "peer": addr, "bytes": size,
            "error": outcome.as_ref().err().map(|(_, m)| m),
        }),
    );
    let resp = match outcome {
        Ok(n) => reply(
            StatusCode::CREATED,
            format!("Saved {n} bytes to {}.", place(&state, &grant)),
        ),
        Err((status, msg)) => {
            state.links.restore(token, grant);
            reply(status, msg)
        }
    };
    private(resp)
}

async fn upload(grant: &Grant, size: u64, body: Body) -> Result<(), (StatusCode, String)> {
    let internal = |e: anyhow::Error| (StatusCode::INTERNAL_SERVER_ERROR, format!("{e:#}"));
    let argv = files_argv(&["write", &grant.path, &size.to_string()]);
    let mut cmd = grant.target.command(&argv, None).map_err(internal)?;
    cmd.stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::piped());
    let mut child = cmd.spawn().context("spawn").map_err(internal)?;
    let mut stdin = child.stdin.take().expect("piped");
    let mut body = StreamReader::new(body.into_data_stream().map_err(std::io::Error::other));
    // a short or broken body closes stdin early, which files.sh detects and
    // answers by leaving the destination untouched
    let copied = tokio::io::copy(&mut body, &mut stdin).await;
    drop(stdin);
    let out = child
        .wait_with_output()
        .await
        .context("wait")
        .map_err(internal)?;
    if out.status.success() {
        return Ok(());
    }
    let mut msg = String::from_utf8_lossy(&out.stderr).trim().to_string();
    if let (true, Err(e)) = (msg.is_empty(), copied) {
        msg = e.to_string();
    }
    Err((failure(&grant.target, out.status.code()), msg))
}

async fn download(state: &AppState, grant: &Grant, addr: Option<String>) -> Response {
    let argv = files_argv(&["read", &grant.path]);
    let mut cmd = match grant.target.command(&argv, None) {
        Ok(c) => c,
        Err(e) => return reply(StatusCode::INTERNAL_SERVER_ERROR, format!("{e:#}")),
    };
    cmd.stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true);
    let mut child = match cmd.spawn() {
        Ok(c) => c,
        Err(e) => return reply(StatusCode::INTERNAL_SERVER_ERROR, format!("spawn: {e}")),
    };
    let mut out = BufReader::new(child.stdout.take().expect("piped"));
    let mut err = child.stderr.take().expect("piped");

    // files.sh prints the size on its own line before the bytes
    let mut line = String::new();
    let size = match out.read_line(&mut line).await {
        Ok(_) => line.trim().parse::<u64>().ok(),
        Err(_) => None,
    };
    let audit = |bytes: Option<u64>, error: Option<&str>| {
        state.audit.record(
            "link_use",
            json!({
                "call": grant.call, "direction": "download", "host": grant.target.host(),
                "path": grant.path, "peer": addr, "bytes": bytes, "error": error,
            }),
        );
    };
    let Some(size) = size else {
        let mut msg = String::new();
        let _ = err.read_to_string(&mut msg).await;
        let code = child.wait().await.ok().and_then(|s| s.code());
        audit(None, Some(msg.trim()));
        return reply(failure(&grant.target, code), msg.trim().to_string());
    };
    audit(Some(size), None);
    // the body stream owns stdout. this task keeps the child reaped and its
    // stderr drained until the stream ends or the client goes away
    tokio::spawn(async move {
        let _ = tokio::io::copy(&mut err, &mut tokio::io::sink()).await;
        let _ = child.wait().await;
    });
    (
        [
            (header::CONTENT_TYPE, "application/octet-stream".to_string()),
            (header::CONTENT_LENGTH, size.to_string()),
            (header::CONTENT_DISPOSITION, attachment(&grant.path)),
        ],
        Body::from_stream(ReaderStream::new(out)),
    )
        .into_response()
}

fn page(state: &AppState, grant: &Grant) -> Response {
    let left = grant.expires.saturating_duration_since(Instant::now());
    let html = UPLOAD_HTML
        .replace("{{ dest }}", &escape(&place(state, grant)))
        .replace("{{ ttl }}", &minutes(left));
    (
        [
            (header::CONTENT_TYPE, "text/html; charset=utf-8"),
            (
                header::CONTENT_SECURITY_POLICY,
                "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'",
            ),
        ],
        html,
    )
        .into_response()
}

// a well-formed token that is not live has expired or been spent. it gets 410
// so retrying an old link does not count toward the 404 ban
fn missing(token: &str) -> Response {
    let ours = URL_SAFE_NO_PAD
        .decode(token)
        .is_ok_and(|b| b.len() == TOKEN_BYTES);
    if ours {
        reply(
            StatusCode::GONE,
            "This link has expired or was already used.",
        )
    } else {
        reply(StatusCode::NOT_FOUND, "Not found.")
    }
}

fn failure(target: &Target, code: Option<i32>) -> StatusCode {
    match (target, code) {
        (Target::Ssh(_), Some(SSH_FAILED)) => StatusCode::BAD_GATEWAY,
        _ => StatusCode::CONFLICT,
    }
}

// whole minutes, rounded up so a live link never reads as 0
pub fn minutes(d: Duration) -> String {
    match d.as_secs().div_ceil(60) {
        1 => "1 minute".to_string(),
        n => format!("{n} minutes"),
    }
}

fn place(state: &AppState, grant: &Grant) -> String {
    let host = grant.target.host().unwrap_or(&state.hostname);
    format!("{host}:{}", grant.path)
}

fn reply(status: StatusCode, msg: impl Into<String>) -> Response {
    (status, format!("{}\n", msg.into())).into_response()
}

fn private(mut resp: Response) -> Response {
    let h = resp.headers_mut();
    h.insert(header::CACHE_CONTROL, HeaderValue::from_static("no-store"));
    h.insert(
        header::REFERRER_POLICY,
        HeaderValue::from_static("no-referrer"),
    );
    h.insert(
        HeaderName::from_static("x-robots-tag"),
        HeaderValue::from_static("noindex"),
    );
    resp
}

// RFC 6266 with the RFC 8187 encoding, which every current browser reads
fn attachment(path: &str) -> String {
    let name = path
        .rsplit('/')
        .next()
        .filter(|n| !n.is_empty())
        .unwrap_or("download");
    let mut v = String::from("attachment; filename*=UTF-8''");
    for b in name.bytes() {
        if b.is_ascii_alphanumeric() || b"!#$&+-.^_`|~".contains(&b) {
            v.push(b as char);
        } else {
            v.push_str(&format!("%{b:02X}"));
        }
    }
    v
}

fn escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;
    use tokio::io::AsyncWriteExt;

    async fn files(args: &[&str], stdin: &[u8]) -> std::process::Output {
        let mut cmd = Target::Local.command(&files_argv(args), None).unwrap();
        cmd.stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());
        let mut child = cmd.spawn().unwrap();
        let mut w = child.stdin.take().unwrap();
        // the script may exit before reading everything
        let _ = w.write_all(stdin).await;
        drop(w);
        child.wait_with_output().await.unwrap()
    }

    #[tokio::test]
    async fn write_then_read() {
        let dir = tempdir("write_then_read");
        let path = dir.join("f.bin");
        let path = path.to_str().unwrap();
        let data: Vec<u8> = (0..=255u8).cycle().take(70_000).collect();

        std::fs::write(path, b"old").unwrap();
        std::fs::set_permissions(path, PermissionsExt::from_mode(0o751)).unwrap();
        let n = data.len().to_string();
        let w = files(&["write", path, &n], &data).await;
        assert!(w.status.success(), "{w:?}");
        assert_eq!(std::fs::read(path).unwrap(), data);
        let mode = std::fs::metadata(path).unwrap().permissions().mode() & 0o777;
        assert_eq!(mode, 0o751);

        let r = files(&["read", path], b"").await;
        assert!(r.status.success(), "{r:?}");
        let mut expect = format!("{n}\n").into_bytes();
        expect.extend_from_slice(&data);
        assert_eq!(r.stdout, expect);
    }

    #[tokio::test]
    async fn short_write_leaves_destination() {
        let dir = tempdir("short_write");
        let path = dir.join("f.txt");
        let path = path.to_str().unwrap();
        std::fs::write(path, b"keep").unwrap();

        let w = files(&["write", path, "10"], b"short").await;
        assert!(!w.status.success());
        assert_eq!(std::fs::read(path).unwrap(), b"keep");
        let names: Vec<_> = std::fs::read_dir(&dir).unwrap().flatten().collect();
        assert_eq!(names.len(), 1, "temp file left behind: {names:?}");
    }

    fn tempdir(name: &str) -> std::path::PathBuf {
        let d = std::env::temp_dir().join(format!("mcp-links-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&d);
        std::fs::create_dir_all(&d).unwrap();
        d
    }
}
