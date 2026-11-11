use std::cmp::Reverse;
use std::collections::BTreeMap;
use std::fmt;
use std::fs;
use std::path::{Component, Path, PathBuf};

use jiff::civil::Date;
use serde::Deserialize;

use crate::Error;
use crate::asset::walk;

/// A url path that starts with '/' and ends with '/' only as the root.
#[derive(Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Route(String);

impl Route {
    fn from_source(rel: &Path) -> Result<Route, Error> {
        let stem = rel.with_extension("");
        let mut parts = Vec::new();
        for component in stem.components() {
            match component {
                Component::Normal(part) => parts.push(
                    part.to_str()
                        .ok_or_else(|| Error::new(format!("{} is not utf-8", rel.display())))?,
                ),
                _ => return Err(Error::new(format!("{} is not a plain path", rel.display()))),
            }
        }
        if parts.last() == Some(&"index") {
            parts.pop();
        }
        Route::new(&format!("/{}", parts.join("/")))
    }

    fn new(path: &str) -> Result<Route, Error> {
        let path = if path.len() > 1 {
            path.trim_end_matches('/')
        } else {
            path
        };
        let clean = path.starts_with('/')
            && !path.contains("//")
            && !path.split('/').any(|part| matches!(part, "." | ".."))
            && path
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b"/-_.".contains(&b));
        if clean {
            Ok(Route(path.to_owned()))
        } else {
            Err(Error::new(format!("{path} is not a usable url path")))
        }
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for Route {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(&self.0)
    }
}

pub enum Layout {
    Article,
    Embed,
    Redirect(String),
    Error(ErrorLayout),
}

#[derive(Clone, Copy)]
pub enum ErrorLayout {
    Generic,
    Waf,
    Widget,
}

#[derive(Deserialize)]
#[serde(try_from = "RawFront")]
pub struct Front {
    pub title: String,
    /// raw html for the h1, the title stays plain text
    pub heading: Option<String>,
    pub description: Option<String>,
    pub created: Date,
    pub updated: Date,
    pub layout: Layout,
    pub hidden: bool,
    pub metas: BTreeMap<String, String>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct RawFront {
    title: String,
    heading: Option<String>,
    description: Option<String>,
    created: Date,
    updated: Date,
    layout: Option<String>,
    #[serde(default)]
    hidden: bool,
    redirect: Option<String>,
    metas: Option<BTreeMap<String, String>>,
}

impl TryFrom<RawFront> for Front {
    type Error = Error;

    fn try_from(raw: RawFront) -> Result<Front, Error> {
        let layout = match (raw.layout.as_deref(), raw.redirect) {
            (Some("redirect"), Some(to)) => Layout::Redirect(to),
            (Some("redirect"), None) => return Err(Error::new("layout redirect needs a redirect")),
            (_, Some(_)) => return Err(Error::new("redirect needs layout redirect")),
            (None | Some("page"), None) => Layout::Article,
            (Some("embed"), None) => Layout::Embed,
            (Some("error/generic"), None) => Layout::Error(ErrorLayout::Generic),
            (Some("error/waf"), None) => Layout::Error(ErrorLayout::Waf),
            (Some("error/widget"), None) => Layout::Error(ErrorLayout::Widget),
            (Some(other), None) => return Err(Error::new(format!("unknown layout {other}"))),
        };
        Ok(Front {
            title: raw.title,
            heading: raw.heading,
            description: raw.description,
            created: raw.created,
            updated: raw.updated,
            layout,
            hidden: raw.hidden,
            metas: raw.metas.unwrap_or_default(),
        })
    }
}

pub struct Page {
    /// relative to the generator crate, for messages
    pub source: PathBuf,
    pub route: Route,
    pub front: Front,
    pub markdown: String,
    pub words: usize,
}

impl Page {
    pub fn minutes(&self) -> usize {
        (self.words / 200).max(1)
    }

    pub fn listed(&self) -> bool {
        !self.front.hidden && self.route.as_str() != "/"
    }
}

/// newest first by created, then updated
pub fn load_all(dir: &Path) -> Result<Vec<Page>, Error> {
    let mut pages = Vec::new();
    walk(dir, &mut |path| {
        if path.extension().is_some_and(|ext| ext == "md") {
            let rel = path.strip_prefix(dir).expect("walk stays under dir");
            pages.push(load(path, rel)?);
        }
        Ok(())
    })?;
    pages.sort_by_key(|p| {
        (
            Reverse(p.front.created),
            Reverse(p.front.updated),
            p.route.clone(),
        )
    });
    Ok(pages)
}

fn load(path: &Path, rel: &Path) -> Result<Page, Error> {
    let source = Path::new("pages").join(rel);
    let fail = |message: &dyn fmt::Display| Error::new(format!("{}: {message}", source.display()));
    let text = fs::read_to_string(path).map_err(|e| fail(&e))?;
    let rest = text
        .strip_prefix("---\n")
        .ok_or_else(|| fail(&"no frontmatter"))?;
    let (yaml, markdown) = match rest.split_once("\n---\n") {
        Some(split) => split,
        None => (
            rest.strip_suffix("\n---")
                .ok_or_else(|| fail(&"unterminated frontmatter"))?,
            "",
        ),
    };
    let front: Front = serde_saphyr::from_str(yaml).map_err(|e| fail(&e))?;
    let route = Route::from_source(rel).map_err(|e| fail(&e))?;
    Ok(Page {
        words: markdown.split_whitespace().count(),
        markdown: markdown.to_owned(),
        source,
        route,
        front,
    })
}
