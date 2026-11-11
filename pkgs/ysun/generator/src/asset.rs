use std::fs;
use std::hash::{DefaultHasher, Hasher};
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::Error;

pub const STYLESHEET: &str = "/assets/style/tailwind.css";

#[derive(Clone, Copy, Debug)]
pub enum Mime {
    Atom,
    Avif,
    Css,
    Csv,
    Gif,
    Html,
    Ico,
    Jpeg,
    Pdf,
    Png,
    Svg,
    Text,
    Xml,
}

impl Mime {
    pub fn of(path: &Path) -> Result<Mime, Error> {
        Ok(match path.extension().and_then(|ext| ext.to_str()) {
            Some("avif") => Mime::Avif,
            Some("css") => Mime::Css,
            Some("csv") => Mime::Csv,
            Some("gif") => Mime::Gif,
            Some("html") => Mime::Html,
            Some("ico") => Mime::Ico,
            Some("jpg" | "jpeg") => Mime::Jpeg,
            Some("pdf") => Mime::Pdf,
            Some("png") => Mime::Png,
            Some("svg") => Mime::Svg,
            Some("txt") => Mime::Text,
            Some("xml") => Mime::Xml,
            _ => return Err(Error::new(format!("{}: unknown file type", path.display()))),
        })
    }

    pub fn header(self) -> &'static str {
        match self {
            Mime::Atom => "application/atom+xml",
            Mime::Avif => "image/avif",
            Mime::Css => "text/css; charset=utf-8",
            Mime::Csv => "text/csv; charset=utf-8",
            Mime::Gif => "image/gif",
            Mime::Html => "text/html; charset=utf-8",
            Mime::Ico => "image/x-icon",
            Mime::Jpeg => "image/jpeg",
            Mime::Pdf => "application/pdf",
            Mime::Png => "image/png",
            Mime::Svg => "image/svg+xml",
            Mime::Text => "text/plain; charset=utf-8",
            Mime::Xml => "application/xml",
        }
    }
}

#[derive(Clone, Copy, Debug)]
pub enum Cache {
    Static,
    Style,
    Page,
}

impl Cache {
    pub fn of(path: &str) -> Cache {
        if path.starts_with("/assets/static/") {
            Cache::Static
        } else if path.starts_with("/assets/style/") {
            Cache::Style
        } else {
            Cache::Page
        }
    }

    pub fn header(self) -> &'static str {
        match self {
            Cache::Static => "public, max-age=604800",
            Cache::Style => "public, max-age=300",
            Cache::Page => "public, no-cache",
        }
    }
}

pub fn etag(bytes: &[u8]) -> String {
    let mut hasher = DefaultHasher::new();
    hasher.write(bytes);
    format!("\"{:016x}\"", hasher.finish())
}

pub fn files(root: &Path) -> Result<Vec<(String, PathBuf)>, Error> {
    let mut files = Vec::new();
    for (dir, prefix) in [("assets/static", "/assets/static/"), ("public", "/")] {
        let dir = root.join(dir);
        walk(&dir, &mut |path| {
            let rel = path.strip_prefix(&dir).expect("walk stays under dir");
            let url = format!("{prefix}{}", rel.to_string_lossy());
            if !url
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b"/-_.".contains(&b))
            {
                return Err(Error::new(format!(
                    "{}: name needs escaping in a url",
                    path.display()
                )));
            }
            files.push((url, path.to_owned()));
            Ok(())
        })?;
    }
    Ok(files)
}

pub fn tailwind(root: &Path) -> Result<Vec<u8>, Error> {
    let output = Command::new("tailwindcss")
        .current_dir(root)
        .args(["--input", "assets/style/tailwind.css", "--minify"])
        .output()
        .map_err(|e| Error::new(format!("tailwindcss: {e}")))?;
    if !output.status.success() {
        return Err(Error::new(format!(
            "tailwindcss: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }
    Ok(output.stdout)
}

/// files under `dir` in name order
pub fn walk(dir: &Path, f: &mut dyn FnMut(&Path) -> Result<(), Error>) -> Result<(), Error> {
    let read = |e: std::io::Error| Error::new(format!("{}: {e}", dir.display()));
    let mut entries = fs::read_dir(dir)
        .map_err(read)?
        .collect::<Result<Vec<_>, _>>()
        .map_err(read)?;
    entries.sort_by_key(|entry| entry.file_name());
    for entry in entries {
        let path = entry.path();
        if entry.file_type().map_err(read)?.is_dir() {
            walk(&path, f)?;
        } else {
            f(&path)?;
        }
    }
    Ok(())
}
