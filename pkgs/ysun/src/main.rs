use std::fmt;
use std::io;
use std::process;

use axum::Router;
use axum::body::{Body, Bytes};
use axum::extract::Request;
use axum::http::header::{ALLOW, CACHE_CONTROL, CONTENT_TYPE, ETAG, IF_NONE_MATCH, LOCATION};
use axum::http::{HeaderValue, Method, StatusCode};
use axum::response::{IntoResponse, Response};
use listenfd::ListenFd;
use tokio::net::{TcpListener, UnixListener};

struct Static {
    content_type: &'static str,
    cache_control: &'static str,
    etag: &'static str,
    body: &'static [u8],
}

// SITE sorted by path, and NOT_FOUND, the index of the page served for unknown paths
include!(concat!(env!("OUT_DIR"), "/site.rs"));

fn fail(message: impl fmt::Display) -> ! {
    eprintln!("ysun: {message}");
    process::exit(1)
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    if std::env::args_os().len() != 1 {
        fail("takes no arguments and serves the socket passed by systemd or systemfd");
    }
    if let Err(e) = serve(Router::new().fallback(handle)).await {
        fail(e);
    }
}

async fn serve(app: Router) -> io::Result<()> {
    let mut fds = ListenFd::from_env();
    if fds.len() != 1 {
        return Err(io::Error::other(
            "expected one activated Unix or TCP listener",
        ));
    }
    match fds.take_unix_listener(0) {
        Ok(listener) => {
            let listener = listener.expect("one unclaimed activation descriptor");
            listener.set_nonblocking(true)?;
            axum::serve(UnixListener::from_std(listener)?, app).await
        }
        Err(e) if e.kind() == io::ErrorKind::InvalidInput => {
            let listener = fds
                .take_tcp_listener(0)?
                .expect("one unclaimed activation descriptor");
            listener.set_nonblocking(true)?;
            let addr = listener.local_addr()?;
            if addr.ip().is_loopback() {
                eprintln!("listening on http://localhost:{}/", addr.port());
            } else {
                eprintln!("listening on http://{addr}/");
            }
            axum::serve(TcpListener::from_std(listener)?, app).await
        }
        Err(e) => Err(e),
    }
}

fn lookup(path: &str) -> Option<&'static Static> {
    SITE.binary_search_by(|(key, _)| (*key).cmp(path))
        .ok()
        .map(|i| &SITE[i].1)
}

async fn handle(request: Request) -> Response {
    if request.method() != Method::GET && request.method() != Method::HEAD {
        return (StatusCode::METHOD_NOT_ALLOWED, [(ALLOW, "GET, HEAD")]).into_response();
    }

    let uri = request.uri();
    if let Some(asset) = lookup(uri.path()) {
        let cached = request
            .headers()
            .get_all(IF_NONE_MATCH)
            .iter()
            .any(|value| not_modified(value, asset.etag));
        let status = if cached {
            StatusCode::NOT_MODIFIED
        } else {
            StatusCode::OK
        };
        return respond(status, asset);
    }

    // the old site's urls ended in a slash
    if let Some(trimmed) = uri.path().strip_suffix('/')
        && lookup(trimmed).is_some()
    {
        let location = match uri.query() {
            Some(query) => HeaderValue::try_from(format!("{trimmed}?{query}")),
            None => HeaderValue::try_from(trimmed),
        }
        .expect("a request path and query form a valid header value");
        return (StatusCode::PERMANENT_REDIRECT, [(LOCATION, location)]).into_response();
    }

    respond(StatusCode::NOT_FOUND, &SITE[NOT_FOUND].1)
}

fn respond(status: StatusCode, asset: &'static Static) -> Response {
    let mut response = if status == StatusCode::NOT_MODIFIED {
        Response::new(Body::empty())
    } else {
        let mut response = Response::new(Body::from(Bytes::from_static(asset.body)));
        response
            .headers_mut()
            .insert(CONTENT_TYPE, HeaderValue::from_static(asset.content_type));
        response
    };
    *response.status_mut() = status;
    let headers = response.headers_mut();
    headers.insert(CACHE_CONTROL, HeaderValue::from_static(asset.cache_control));
    // a 404 carries the error page, whose etag does not describe the requested path
    if status != StatusCode::NOT_FOUND {
        headers.insert(ETAG, HeaderValue::from_static(asset.etag));
    }
    response
}

// weak comparison (RFC 9110 section 13.1.2), the generator's etags are strong
fn not_modified(if_none_match: &HeaderValue, etag: &str) -> bool {
    if_none_match
        .as_bytes()
        .split(|&b| b == b',')
        .map(<[u8]>::trim_ascii)
        .any(|tag| tag == b"*" || tag.strip_prefix(b"W/").unwrap_or(tag) == etag.as_bytes())
}
