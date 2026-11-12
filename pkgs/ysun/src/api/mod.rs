//! the routes under API, which the server answers itself and build.rs keeps the static site out of

mod live;

use axum::Router;

/// the routes relative to API, for nesting under it, with what they serve from started, an unknown
/// path falls through to the site's fallback, which answers everything under API with a bare 404
pub fn router() -> Result<Router, String> {
    Ok(Router::new().route("/live", live::route()?))
}
