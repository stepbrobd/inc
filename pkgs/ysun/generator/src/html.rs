use std::fmt;

use askama::Template;
use jiff::civil::Date;

use crate::ORIGIN;
use crate::asset::Mime;
use crate::markdown::Markdown;
use crate::page::{ErrorLayout, Layout, Page};
use crate::{Entry, Error};

const OG_IMAGE: &str = "/assets/static/img/og.avif";
const FEED_LENGTH: usize = 25;

pub struct StorePath {
    path: String,
    hash: String,
}

impl StorePath {
    pub fn parse(path: &str) -> Result<StorePath, Error> {
        path.strip_prefix("/nix/store/")
            .and_then(|name| name.split_once('-'))
            .filter(|(hash, _)| hash.len() == 32)
            .map(|(hash, _)| StorePath {
                path: path.to_owned(),
                hash: hash.to_owned(),
            })
            .ok_or_else(|| Error::new(format!("{path} is not a nix store path")))
    }
}

#[derive(Clone, Copy)]
enum MetaAttr {
    Name,
    Property,
}

impl fmt::Display for MetaAttr {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(match self {
            MetaAttr::Name => "name",
            MetaAttr::Property => "property",
        })
    }
}

struct Meta {
    attr: MetaAttr,
    key: &'static str,
    content: String,
}

#[derive(Template)]
#[template(path = "page.html")]
struct PageHtml<'a> {
    page: &'a Page,
    body: &'a str,
    canonical: String,
    metas: Vec<Meta>,
    menu: &'a [&'a Page],
    store: Option<&'a StorePath>,
    prefix: &'static str,
    css: &'a str,
}

#[derive(Template)]
#[template(path = "error.html")]
struct ErrorHtml<'a> {
    page: &'a Page,
    body: &'a str,
    kind: ErrorLayout,
    store: Option<&'a StorePath>,
    prefix: &'static str,
    css: &'a str,
}

struct FeedEntry<'a> {
    title: &'a str,
    id: String,
    link: String,
    updated: Date,
    summary: Option<&'a str>,
}

#[derive(Template)]
#[template(path = "atom.xml")]
struct Atom<'a> {
    origin: &'static str,
    updated: Date,
    entries: Vec<FeedEntry<'a>>,
}

#[derive(Template)]
#[template(path = "sitemap.xml")]
struct Sitemap {
    urls: Vec<(String, Date)>,
}

pub fn render(
    pages: &[Page],
    markdown: &Markdown,
    store: Option<&StorePath>,
    css: &str,
) -> Result<Vec<Entry>, Error> {
    markdown.check(OG_IMAGE)?;
    let template = |e: askama::Error| Error::new(format!("template: {e}"));
    let menu: Vec<&Page> = pages.iter().filter(|p| p.listed()).collect();

    let mut entries = Vec::with_capacity(pages.len() + 2);
    for page in pages {
        let html = markdown
            .render(page)
            .map_err(|e| Error::new(format!("{}: {e}", page.source.display())))?;
        let text = match page.front.layout {
            Layout::Error(kind) => ErrorHtml {
                page,
                body: html.body.trim_end(),
                kind,
                store,
                prefix: ORIGIN,
                css,
            }
            .render(),
            _ => PageHtml {
                page,
                body: html.body.trim_end(),
                canonical: format!("{ORIGIN}{}", page.route),
                metas: metas(page, html.og_image.as_deref()),
                menu: &menu,
                store,
                prefix: "",
                css,
            }
            .render(),
        }
        .map_err(template)?;
        entries.push(Entry::bytes(
            page.route.to_string(),
            Mime::Html,
            text.into_bytes(),
        ));
        eprintln!("rendered {} -> {}", page.source.display(), page.route);
    }

    let feed = &menu[..menu.len().min(FEED_LENGTH)];
    let atom = Atom {
        origin: ORIGIN,
        updated: feed
            .iter()
            .map(|p| p.front.updated)
            .max()
            .ok_or_else(|| Error::new("no page for the feed"))?,
        entries: feed
            .iter()
            .map(|p| FeedEntry {
                title: &p.front.title,
                // the old site's ids ended in a slash, kept so readers do not list every entry again
                id: format!("{ORIGIN}{}/", p.route),
                link: format!("{ORIGIN}{}", p.route),
                updated: p.front.updated,
                summary: p.front.description.as_deref(),
            })
            .collect(),
    };
    entries.push(Entry::bytes(
        "/atom.xml".to_owned(),
        Mime::Atom,
        atom.render().map_err(template)?.into_bytes(),
    ));
    eprintln!("rendered /atom.xml");

    let sitemap = Sitemap {
        urls: pages
            .iter()
            .filter(|p| !p.front.hidden && !matches!(p.front.layout, Layout::Redirect(_)))
            .map(|p| (format!("{ORIGIN}{}", p.route), p.front.updated))
            .collect(),
    };
    entries.push(Entry::bytes(
        "/sitemap.xml".to_owned(),
        Mime::Xml,
        sitemap.render().map_err(template)?.into_bytes(),
    ));
    eprintln!("rendered /sitemap.xml");
    Ok(entries)
}

fn metas(page: &Page, og_image: Option<&str>) -> Vec<Meta> {
    let front = &page.front;
    let property = |key, content| Meta {
        attr: MetaAttr::Property,
        key,
        content,
    };
    let mut metas = vec![
        property("og:type", "website".to_owned()),
        property("og:locale", "en_US".to_owned()),
        property("og:title", front.title.clone()),
        property("og:url", format!("{ORIGIN}{}", page.route)),
        property(
            "og:image",
            format!("{ORIGIN}{}", og_image.unwrap_or(OG_IMAGE)),
        ),
        Meta {
            attr: MetaAttr::Name,
            key: "twitter:card",
            content: "summary_large_image".to_owned(),
        },
    ];
    if let Some(description) = &front.description {
        metas.push(property("og:description", description.clone()));
        metas.push(Meta {
            attr: MetaAttr::Name,
            key: "description",
            content: description.clone(),
        });
    }
    metas
}
