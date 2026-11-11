use std::collections::{HashMap, HashSet};
use std::fmt::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use comrak::adapters::{HeadingAdapter, HeadingMeta};
use comrak::html::{escape, escape_href};
use comrak::nodes::{AstNode, NodeHtmlBlock, NodeValue, Sourcepos};
use comrak::options::Plugins;
use comrak::{Anchorizer, Arena, Options, format_html_with_plugins, parse_document};
use giallo::{HighlightOptions, HtmlRenderer, Registry, RenderOptions, ThemeVariant};
use html5gum::{DefaultEmitter, Token, Tokenizer};
use math_core::{LatexToMathML, MathCoreConfig, MathDisplay};

use crate::page::{Layout, Page};
use crate::{Error, ORIGIN};

const THEME: &str = "nord";

/// the path of a url on this site, none for fragments and other sites
fn local(url: &str) -> Result<Option<&str>, Error> {
    let url = match url.strip_prefix(ORIGIN) {
        Some("") => "/",
        Some(rest) if rest.starts_with('/') => rest,
        _ => url,
    };
    let scheme = url.split_once(':').is_some_and(|(scheme, _)| {
        scheme.starts_with(|c: char| c.is_ascii_alphabetic())
            && scheme
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b"+-.".contains(&b))
    });
    if url.starts_with('#') || url.starts_with("//") || scheme {
        return Ok(None);
    }
    let path = &url[..url.find(['?', '#']).unwrap_or(url.len())];
    if path.starts_with('/') {
        Ok(Some(path))
    } else {
        // relative links resolve against a different base once urls lose the trailing slash
        Err(Error::new(format!("relative link {url}")))
    }
}

pub struct Markdown<'a> {
    options: Options<'static>,
    registry: Registry,
    math: LatexToMathML,
    files: HashMap<&'a str, &'a Path>,
    known: &'a HashSet<&'a str>,
}

pub struct Html {
    pub body: String,
    /// first image served from this site, for og:image
    pub og_image: Option<String>,
}

impl<'a> Markdown<'a> {
    pub fn new(
        files: &'a [(String, PathBuf)],
        known: &'a HashSet<&'a str>,
    ) -> Result<Markdown<'a>, Error> {
        let mut registry = Registry::builtin().map_err(Error::new)?;
        registry.link_grammars();
        if !registry.contains_theme(THEME) {
            return Err(Error::new(format!("giallo has no theme {THEME}")));
        }
        let math = LatexToMathML::new(MathCoreConfig::default(), Vec::new())
            .map_err(|e| Error::new(format!("math-core: {e:?}")))?;

        let mut options = Options::default();
        options.extension.alerts = true;
        options.extension.autolink = true;
        options.extension.footnotes = true;
        options.extension.math_dollars = true;
        options.extension.math_code = true;
        options.extension.strikethrough = true;
        options.extension.table = true;
        options.extension.tasklist = true;
        // pages embed iframes and scripts
        options.render.r#unsafe = true;

        Ok(Markdown {
            options,
            registry,
            math,
            files: files
                .iter()
                .map(|(url, path)| (url.as_str(), path.as_path()))
                .collect(),
            known,
        })
    }

    pub fn render(&self, page: &Page) -> Result<Html, Error> {
        if let Layout::Redirect(to) = &page.front.layout {
            self.check(to)?;
        }
        if let Some(heading) = &page.front.heading {
            self.check_html(heading)?;
        }
        let arena = Arena::new();
        let root = parse_document(&arena, &page.markdown, &self.options);
        let mut og_image = None;

        let nodes: Vec<_> = root.descendants().collect();
        for node in nodes {
            let mut target = node;
            let replacement = match &node.data.borrow().value {
                NodeValue::Image(image) => {
                    // check_html rejects local images that are not files
                    let file = local(&image.url)?.and_then(|path| self.files.get_key_value(path));
                    if let Some((path, _)) = file {
                        og_image.get_or_insert_with(|| (*path).to_owned());
                    }
                    let figure = node.parent().filter(|parent| {
                        matches!(parent.data.borrow().value, NodeValue::Paragraph)
                            && node.previous_sibling().is_none()
                            && node.next_sibling().is_none()
                    });
                    let path = file.map(|(_, path)| *path);
                    let literal =
                        self.image(node, &image.url, &image.title, path, figure.is_some())?;
                    Some(if let Some(parent) = figure {
                        target = parent;
                        NodeValue::HtmlBlock(NodeHtmlBlock {
                            block_type: 0,
                            literal,
                        })
                    } else {
                        NodeValue::HtmlInline(literal)
                    })
                }
                NodeValue::Math(math) => Some(NodeValue::HtmlInline(
                    self.math(&math.literal, math.display_math)?,
                )),
                NodeValue::CodeBlock(code)
                    if code.info.split_whitespace().next() == Some("math") =>
                {
                    Some(NodeValue::HtmlBlock(NodeHtmlBlock {
                        block_type: 0,
                        literal: self.math(&code.literal, true)?,
                    }))
                }
                NodeValue::CodeBlock(code) => Some(NodeValue::HtmlBlock(NodeHtmlBlock {
                    block_type: 0,
                    literal: self.code(&code.info, &code.literal)?,
                })),
                _ => None,
            };
            if let Some(value) = replacement {
                while let Some(child) = target.first_child() {
                    child.detach();
                }
                target.data.borrow_mut().value = value;
            }
        }

        let headings = Headings(Mutex::new(Anchorizer::new()));
        let mut plugins = Plugins::default();
        plugins.render.heading_adapter = Some(&headings);
        let mut body = String::new();
        format_html_with_plugins(root, &self.options, &mut body, &plugins).map_err(Error::new)?;
        self.check_html(&body)?;
        Ok(Html { body, og_image })
    }

    /// fragments, other sites and the exact paths this site serves pass, so an
    /// internal link never costs the trailing slash redirect
    pub fn check(&self, url: &str) -> Result<(), Error> {
        match local(url)? {
            Some(path) if !self.known.contains(path) => Err(Error::new(format!(
                "link to {url}, which this site does not serve"
            ))),
            _ => Ok(()),
        }
    }

    fn check_image(&self, url: &str) -> Result<(), Error> {
        match local(url)? {
            Some(path) if !self.files.contains_key(path) => Err(Error::new(format!(
                "image {url} is not a file under assets/static or public"
            ))),
            _ => Ok(()),
        }
    }

    /// checks href, src, poster and action, not srcset or urls in scripts and styles
    fn check_html(&self, html: &str) -> Result<(), Error> {
        let mut emitter = DefaultEmitter::default();
        // do not interpret markup inside scripts, styles, or comments as links
        emitter.naively_switch_states(true);
        for token in Tokenizer::new_with_emitter(html, emitter) {
            if let Token::StartTag(tag) = token.map_err(Error::new)? {
                for (name, value) in &tag.attributes {
                    let name: &[u8] = name;
                    if matches!(name, b"href" | b"src" | b"poster" | b"action") {
                        let url = std::str::from_utf8(value).map_err(Error::new)?.trim();
                        if (tag.name.as_slice() == b"img" && name == b"src") || name == b"poster" {
                            self.check_image(url)?;
                        } else {
                            self.check(url)?;
                        }
                    }
                }
            }
        }
        Ok(())
    }

    fn image(
        &self,
        node: &'a AstNode<'a>,
        url: &str,
        title: &str,
        path: Option<&Path>,
        figure: bool,
    ) -> Result<String, Error> {
        let mut alt = String::new();
        for child in node.descendants().skip(1) {
            match &child.data.borrow().value {
                NodeValue::Text(text) => alt.push_str(text),
                NodeValue::Code(code) => alt.push_str(&code.literal),
                NodeValue::SoftBreak | NodeValue::LineBreak => alt.push(' '),
                _ => {}
            }
        }
        let caption = figure && !alt.trim().is_empty();
        let mut html = String::new();
        if figure {
            html.push_str("<figure>");
        }
        html.push_str("<img src=\"");
        escape_href(&mut html, url, false).map_err(Error::new)?;
        html.push_str("\" alt=\"");
        if !caption {
            escape(&mut html, &alt).map_err(Error::new)?;
        }
        html.push_str("\" loading=\"lazy\" decoding=\"async\"");
        if !title.is_empty() {
            html.push_str(" title=\"");
            escape(&mut html, title).map_err(Error::new)?;
            html.push('"');
        }
        if let Some(path) = path {
            let size = imagesize::size(path).map_err(|e| Error::new(format!("{url}: {e}")))?;
            write!(html, " width=\"{}\" height=\"{}\"", size.width, size.height)
                .map_err(Error::new)?;
        }
        html.push_str(" />");
        if caption {
            html.push_str("<figcaption>");
            escape(&mut html, &alt).map_err(Error::new)?;
            html.push_str("</figcaption>");
        }
        if figure {
            html.push_str("</figure>");
        }
        Ok(html)
    }

    fn math(&self, latex: &str, display: bool) -> Result<String, Error> {
        let display = if display {
            MathDisplay::Block
        } else {
            MathDisplay::Inline
        };
        self.math
            .convert_with_local_state(latex, display)
            .map(|result| result.mathml)
            .map_err(|e| Error::new(format!("math {latex}: {e:?}")))
    }

    fn code(&self, info: &str, literal: &str) -> Result<String, Error> {
        let lang = info.split_whitespace().next().unwrap_or("txt");
        if !self.registry.contains_grammar(lang) {
            return Err(Error::new(format!(
                "no grammar for code block language {lang}"
            )));
        }
        let highlighted = self
            .registry
            .highlight(
                literal,
                &HighlightOptions::new(lang, ThemeVariant::Single(THEME)),
            )
            .map_err(Error::new)?;
        Ok(HtmlRenderer::default().render(&highlighted, &RenderOptions::default()))
    }
}

struct Headings(Mutex<Anchorizer>);

impl HeadingAdapter for Headings {
    fn enter(
        &self,
        output: &mut dyn fmt::Write,
        heading: &HeadingMeta,
        _: Option<Sourcepos>,
    ) -> fmt::Result {
        let id = self
            .0
            .lock()
            .map_err(|_| fmt::Error)?
            .anchorize(&heading.content);
        write!(
            output,
            "<h{level} id=\"{id}\" tabindex=\"-1\"><a class=\"header-anchor\" href=\"#{id}\" aria-hidden=\"true\" tabindex=\"-1\">#</a> ",
            level = heading.level,
        )
    }

    fn exit(&self, output: &mut dyn fmt::Write, heading: &HeadingMeta) -> fmt::Result {
        writeln!(output, "</h{}>", heading.level)
    }
}
