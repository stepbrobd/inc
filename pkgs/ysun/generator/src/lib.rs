mod asset;
mod html;
mod markdown;
mod page;

use std::collections::HashSet;
use std::fmt;
use std::fs;
use std::path::{Path, PathBuf};

pub use asset::{Cache, Mime};

const ORIGIN: &str = "https://ysun.co";

#[derive(Debug)]
pub struct Error(String);

impl Error {
    fn new(message: impl fmt::Display) -> Error {
        Error(message.to_string())
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::error::Error for Error {}

pub enum Body {
    File(PathBuf),
    Bytes(Vec<u8>),
}

pub struct Entry {
    pub path: String,
    pub mime: Mime,
    pub cache: Cache,
    pub etag: String,
    pub body: Body,
}

impl Entry {
    fn bytes(path: String, mime: Mime, bytes: Vec<u8>) -> Entry {
        Entry {
            cache: Cache::of(&path),
            etag: asset::etag(&bytes),
            path,
            mime,
            body: Body::Bytes(bytes),
        }
    }
}

/// Every served path, sorted and unique.
pub struct Site {
    pub entries: Vec<Entry>,
}

pub fn render(root: &Path, store_path: Option<&str>) -> Result<Site, Error> {
    let pages = page::load_all(&root.join("pages"))?;
    let files = asset::files(root)?;
    let mut known = HashSet::new();
    for path in pages
        .iter()
        .map(|page| page.route.as_str())
        .chain(["/atom.xml", "/sitemap.xml", asset::STYLESHEET])
        .chain(files.iter().map(|(url, _)| url.as_str()))
    {
        if !known.insert(path) {
            return Err(Error::new(format!("{path} is served twice")));
        }
    }
    let markdown = markdown::Markdown::new(&files, &known)?;
    let store = store_path.map(html::StorePath::parse).transpose()?;

    let mut entries = html::render(&pages, &markdown, store.as_ref())?;
    entries.push(Entry::bytes(
        asset::STYLESHEET.to_owned(),
        Mime::Css,
        asset::tailwind(root)?,
    ));
    for (url, path) in &files {
        let bytes = fs::read(path).map_err(|e| Error::new(format!("{}: {e}", path.display())))?;
        entries.push(Entry {
            path: url.clone(),
            mime: Mime::of(path)?,
            cache: Cache::of(url),
            etag: asset::etag(&bytes),
            body: Body::File(path.clone()),
        });
    }

    // entries cover exactly the paths in known, which are unique
    entries.sort_by(|a, b| a.path.cmp(&b.path));
    Ok(Site { entries })
}
