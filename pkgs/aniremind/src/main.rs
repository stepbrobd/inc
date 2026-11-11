use std::collections::{HashMap, HashSet};
use std::fmt;
use std::io::{self, IsTerminal, Write};
use std::process::{self, Command, ExitCode, Output};
use std::sync::Arc;
use std::time::Duration;

use clap::{CommandFactory, Parser, ValueEnum};
use clap_complete::generate;
use clap_complete_nushell::Nushell;
use jiff::Timestamp;
use jiff::tz::TimeZone;
use serde::Deserialize;
use serde::de::DeserializeOwned;
use serde_json::{Value, json};

const ENDPOINT: &str = "https://graphql.anilist.co";
const TIMEOUT: Duration = Duration::from_secs(30);
const QUERY: &str = "
query Watching($user: String) {
  MediaListCollection(userName: $user, type: ANIME, status: CURRENT) {
    lists {
      entries {
        media {
          id
          siteUrl
          title { native english romaji }
          airingSchedule(notYetAired: true, perPage: 50) {
            nodes { episode airingAt }
          }
        }
      }
    }
  }
}";

/// Sync an AniList watchlist into Things 3
#[derive(Parser)]
#[command(name = "aniremind")]
struct Args {
    /// AniList username
    #[arg(short, long, required = true)]
    user: Option<String>,

    /// Where the to-dos go: inbox, or an area or project by title or id prefix
    #[arg(short = 'i', long = "in", value_name = "CONTAINER", required = true)]
    container: Option<String>,

    /// Write without asking to confirm
    #[arg(short, long)]
    yes: bool,

    /// Print the completion script for a shell and exit
    #[arg(long, value_name = "SHELL", exclusive = true)]
    completions: Option<Shell>,
}

#[derive(Clone, Copy, ValueEnum)]
enum Shell {
    Bash,
    Fish,
    Nushell,
    Zsh,
}

#[derive(Deserialize)]
struct Response {
    data: Option<Value>,
    errors: Option<Vec<Message>>,
}

#[derive(Deserialize)]
struct Message {
    message: String,
}

#[derive(Deserialize)]
struct Data {
    #[serde(rename = "MediaListCollection")]
    collection: Option<Collection>,
}

#[derive(Deserialize)]
struct Collection {
    lists: Vec<Group>,
}

#[derive(Deserialize)]
struct Group {
    entries: Vec<Entry>,
}

#[derive(Deserialize)]
struct Entry {
    media: Media,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Media {
    id: i32,
    site_url: String,
    title: Title,
    airing_schedule: Schedule,
}

#[derive(Deserialize)]
struct Title {
    native: Option<String>,
    english: Option<String>,
    romaji: Option<String>,
}

#[derive(Deserialize)]
struct Schedule {
    nodes: Vec<Node>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Node {
    episode: i32,
    airing_at: i32,
}

#[derive(Deserialize)]
struct Task {
    id: String,
    title: String,
    status: String,
    #[serde(rename = "type")]
    kind: String,
    notes: Option<String>,
    project: Option<Link>,
    area: Option<Link>,
    start: Start,
    flags: Flags,
}

#[derive(Deserialize)]
struct Link {
    id: String,
    title: String,
}

#[derive(Deserialize)]
struct Start {
    scheduled_at: Option<String>,
    reminder: Option<String>,
}

#[derive(Deserialize)]
struct Flags {
    degraded: bool,
}

struct Episode {
    url: String,
    number: i32,
    title: String,
    when: String,
    at: String,
}

struct Existing {
    id: String,
    title: String,
    status: String,
    when: Option<String>,
    at: Option<String>,
    degraded: bool,
    container: Container,
}

#[derive(Clone)]
struct Container {
    id: String,
    title: String,
    kind: Option<&'static str>,
}

impl Container {
    fn inbox() -> Self {
        Self {
            id: "inbox".into(),
            title: "Inbox".into(),
            kind: None,
        }
    }

    fn of(link: Link, kind: &'static str) -> Self {
        Self {
            id: link.id,
            title: link.title,
            kind: Some(kind),
        }
    }
}

impl fmt::Display for Container {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self.kind {
            Some(kind) => write!(f, "{} ({kind})", self.title),
            None => f.write_str(&self.title),
        }
    }
}

enum Step<'a> {
    Create,
    Hold,
    Update(&'a Existing, String),
}

fn fail(message: impl fmt::Display) -> ! {
    eprintln!("{message}");
    process::exit(1)
}

fn anilist(user: &str) -> Vec<Media> {
    let tls = ureq::tls::TlsConfig::builder()
        .root_certs(ureq::tls::RootCerts::PlatformVerifier)
        .unversioned_rustls_crypto_provider(Arc::new(rustls::crypto::ring::default_provider()))
        .build();
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(TIMEOUT))
        .http_status_as_error(false)
        .tls_config(tls)
        .build()
        .into();
    let mut response = agent
        .post(ENDPOINT)
        .send_json(json!({"query": QUERY, "variables": {"user": user}}))
        .unwrap_or_else(|err| fail(format!("AniList request failed: {err}")));
    let status = response.status();
    let body = response
        .body_mut()
        .read_to_string()
        .unwrap_or_else(|err| fail(format!("AniList request failed: {err}")));

    let payload: Response = match serde_json::from_str(&body) {
        Ok(payload) => payload,
        Err(_) if !status.is_success() => {
            fail(format!("AniList answered HTTP {}", status.as_u16()))
        }
        Err(err) => fail(format!(
            "AniList answered with a body that is not JSON: {err}"
        )),
    };
    // errors go first, since a failed field leaves a null the data cannot parse
    let messages: Vec<String> = payload
        .errors
        .into_iter()
        .flatten()
        .map(|e| e.message)
        .collect();
    if !messages.is_empty() {
        fail(format!("AniList: {}", messages.join("; ")));
    }
    let collection = payload
        .data
        .map(|data| {
            serde_json::from_value::<Data>(data).unwrap_or_else(|err| {
                fail(format!(
                    "AniList answered a watchlist it did not describe: {err}"
                ))
            })
        })
        .and_then(|data| data.collection)
        .unwrap_or_else(|| fail(format!("AniList returned no watchlist for user {user}")));

    let mut seen = HashSet::new();
    collection
        .lists
        .into_iter()
        .flat_map(|group| group.entries)
        .map(|entry| entry.media)
        .filter(|media| seen.insert(media.id))
        .collect()
}

fn episodes(media: &[Media], tz: &TimeZone) -> Vec<Episode> {
    let mut rows = Vec::new();
    for item in media {
        let title = &item.title;
        let name = [&title.native, &title.romaji, &title.english]
            .into_iter()
            .flatten()
            .find(|name| !name.is_empty())
            .map_or("(untitled)", String::as_str);
        // kana and cjk, to mark an episode in the script the title is written in
        let cjk = name
            .chars()
            .any(|c| matches!(c, '\u{3040}'..='\u{30ff}' | '\u{4e00}'..='\u{9fff}'));
        for node in &item.airing_schedule.nodes {
            let number = node.episode;
            let mark = if cjk {
                format!("第{number}話")
            } else {
                format!("Episode {number}")
            };
            let airs = tz.to_datetime(
                Timestamp::from_second(node.airing_at.into()).expect("i32 seconds fit a timestamp"),
            );
            rows.push(Episode {
                url: item.site_url.clone(),
                number,
                title: format!("{name} {mark}"),
                when: airs.strftime("%Y-%m-%d").to_string(),
                at: airs.strftime("%H:%M").to_string(),
            });
        }
    }
    rows
}

fn things(args: &[&str]) -> Output {
    Command::new("things")
        .args(args)
        .output()
        .unwrap_or_else(|err| match err.kind() {
            io::ErrorKind::NotFound => fail(
                "Could not find things in PATH, install it from https://github.com/stepbrobd/things",
            ),
            _ => fail(format!("Could not run things: {err}")),
        })
}

fn view<T: DeserializeOwned>(args: &[&str]) -> T {
    let name = args.join(" ");
    let out = things(&[["--json"].as_slice(), args].concat());
    let stderr = String::from_utf8_lossy(&out.stderr);
    if !out.status.success() {
        fail(format!("The things {name} view failed: {}", stderr.trim()));
    }
    // the cli warns and serves its cache, which would read as missing to-dos
    if stderr.contains("Sync failed") {
        fail(format!(
            "Things could not reach Things Cloud: {}",
            stderr.trim()
        ));
    }
    serde_json::from_slice(&out.stdout)
        .unwrap_or_else(|err| fail(format!("The things {name} view did not answer JSON: {err}")))
}

fn owned(notes: &str) -> Option<&str> {
    let url = notes.trim();
    let id = url.strip_prefix("https://anilist.co/anime/")?;
    (!id.is_empty() && id.bytes().all(|b| b.is_ascii_digit())).then_some(url)
}

fn number(title: &str) -> Option<i32> {
    let title = title.trim_end();
    let (body, marker) = match title.strip_suffix('話') {
        Some(body) => (body, "第"),
        None => (title, "episode "),
    };
    let rest = body.trim_end_matches(|c: char| c.is_ascii_digit());
    let digits = &body[rest.len()..];
    let tail = &rest.as_bytes()[rest.len().checked_sub(marker.len())?..];
    if digits.is_empty() || !tail.eq_ignore_ascii_case(marker.as_bytes()) {
        return None;
    }
    digits.parse().ok()
}

fn synced() -> HashMap<(String, i32), Existing> {
    let mut index = HashMap::new();
    for task in view::<Vec<Task>>(&["find", "--any-status"]) {
        if task.kind != "todo" {
            continue;
        }
        let (Some(url), Some(episode)) = (
            owned(task.notes.as_deref().unwrap_or_default()),
            number(&task.title),
        ) else {
            continue;
        };
        let container = match (task.project, task.area) {
            (Some(project), _) => Container::of(project, "project"),
            (None, Some(area)) => Container::of(area, "area"),
            (None, None) => Container::inbox(),
        };
        let existing = Existing {
            id: task.id,
            title: task.title,
            status: task.status,
            // a day stamp is written at utc midnight so the day reads off the front
            when: task
                .start
                .scheduled_at
                .map(|at| at.chars().take(10).collect()),
            at: task.start.reminder,
            degraded: task.flags.degraded,
            container,
        };
        index.insert((url.to_string(), episode), existing);
    }
    index
}

fn find_container(target: &str) -> Container {
    if target.eq_ignore_ascii_case("inbox") {
        return Container::inbox();
    }
    let areas = view::<Vec<Link>>(&["areas", "list"]);
    let projects = view::<Vec<Link>>(&["projects", "list"]);
    let known: Vec<Container> = areas
        .into_iter()
        .map(|link| Container::of(link, "area"))
        .chain(
            projects
                .into_iter()
                .map(|link| Container::of(link, "project")),
        )
        .collect();
    let lower = target.to_lowercase();
    let exact: Vec<&Container> = known
        .iter()
        .filter(|item| item.title.to_lowercase() == lower)
        .collect();
    let hits = if exact.is_empty() {
        known
            .iter()
            .filter(|item| item.id.starts_with(target))
            .collect()
    } else {
        exact
    };
    match hits[..] {
        [hit] => hit.clone(),
        [] => fail(format!(
            "Container not found: {target}. Known: {}",
            labels(&known)
        )),
        _ => fail(format!(
            "Container {target} is ambiguous, it matches: {}",
            labels(hits)
        )),
    }
}

fn labels<'a>(items: impl IntoIterator<Item = &'a Container>) -> String {
    let labels: Vec<String> = items.into_iter().map(ToString::to_string).collect();
    labels.join(", ")
}

fn drift(current: &Existing, row: &Episode, target: &Container) -> Option<String> {
    let mut parts = Vec::new();
    if current.title != row.title {
        parts.push(format!("titled {}", current.title));
    }
    if (current.when.as_deref(), current.at.as_deref()) != (Some(&*row.when), Some(&*row.at)) {
        let when = current.when.as_deref().unwrap_or("-");
        let at = current.at.as_deref().unwrap_or("-");
        parts.push(format!("at {when} {at}"));
    }
    if current.container.id != target.id {
        parts.push(format!("in {}", current.container));
    }
    (!parts.is_empty()).then(|| format!("was {}", parts.join(", ")))
}

fn create(row: &Episode, target: &Container) -> Output {
    things(&[
        "new",
        "--in",
        &target.id,
        "--when",
        &row.when,
        "--reminder",
        &row.at,
        "--notes",
        &row.url,
        // -- guards a title that starts with a hyphen
        "--",
        &row.title,
    ])
}

fn edit(row: &Episode, current: &Existing, target: &Container) -> Output {
    // --title= keeps clap from reading a leading hyphen as a flag
    let title = format!("--title={}", row.title);
    let mut args = vec![
        "edit",
        &current.id,
        "--when",
        &row.when,
        "--reminder",
        &row.at,
    ];
    if current.title != row.title {
        args.push(&title);
    }
    if current.container.id != target.id {
        // --move inbox is refused alongside a day, clear keeps it and lands the same
        args.extend([
            "--move",
            if target.id == "inbox" {
                "clear"
            } else {
                &target.id
            },
        ]);
    }
    things(&args)
}

fn confirm(count: usize) -> bool {
    if !io::stdin().is_terminal() {
        fail("Refusing to write without -y when there is no terminal to confirm at");
    }
    print!("\nApply {count} changes? [y/N] ");
    let mut answer = String::new();
    io::stdout()
        .flush()
        .and_then(|()| io::stdin().read_line(&mut answer))
        .unwrap_or_else(|err| fail(format!("Could not read the answer: {err}")));
    matches!(answer.trim().to_lowercase().as_str(), "y" | "yes")
}

fn main() -> ExitCode {
    let args = Args::parse();
    if let Some(shell) = args.completions {
        let mut command = Args::command();
        let name = command.get_name().to_string();
        let out = &mut io::stdout();
        match shell {
            Shell::Bash => generate(clap_complete::Shell::Bash, &mut command, name, out),
            Shell::Fish => generate(clap_complete::Shell::Fish, &mut command, name, out),
            Shell::Nushell => generate(Nushell, &mut command, name, out),
            Shell::Zsh => generate(clap_complete::Shell::Zsh, &mut command, name, out),
        }
        return ExitCode::SUCCESS;
    }
    let (Some(user), Some(container)) = (args.user, args.container) else {
        unreachable!("clap requires --user and --in without --completions")
    };

    let tz = TimeZone::try_system()
        .unwrap_or_else(|err| fail(format!("Could not read the local time zone: {err}")));
    println!(
        "Timezone: {}",
        Timestamp::now().to_zoned(tz.clone()).strftime("%Z %z")
    );
    let media = anilist(&user);
    let mut rows = episodes(&media, &tz);
    rows.sort_by(|a, b| (&a.when, &a.at, &a.title).cmp(&(&b.when, &b.at, &b.title)));
    println!(
        "AniList: {} shows, {} unaired episodes",
        media.len(),
        rows.len()
    );
    let target = find_container(&container);
    println!("Container: {target}");
    let index = synced();

    let mut plan = Vec::new();
    let mut settled = 0;
    for row in &rows {
        match index.get(&(row.url.clone(), row.number)) {
            None => plan.push((row, Step::Create)),
            Some(current) if current.degraded => plan.push((row, Step::Hold)),
            Some(current) if current.status != "incomplete" => settled += 1,
            Some(current) => match drift(current, row, &target) {
                Some(drift) => plan.push((row, Step::Update(current, drift))),
                None => settled += 1,
            },
        }
    }

    if !plan.is_empty() {
        println!();
    }
    for (row, step) in &plan {
        let line = format!("{} {}  {}", row.when, row.at, row.title);
        match step {
            Step::Create => println!("  create  {line}"),
            Step::Hold => println!("  hold    {line}  (degraded, things refuses to write it)"),
            Step::Update(_, drift) => println!("  update  {line}  ({drift})"),
        }
    }

    let held = plan
        .iter()
        .filter(|(_, step)| matches!(step, Step::Hold))
        .count();
    let writes = plan.len() - held;
    if writes == 0 {
        println!("\nNothing to write, {held} held, {settled} up to date");
        return if held > 0 {
            ExitCode::FAILURE
        } else {
            ExitCode::SUCCESS
        };
    }
    if !args.yes && !confirm(writes) {
        println!("Nothing written");
        return ExitCode::SUCCESS;
    }

    let (mut created, mut updated, mut failed) = (0, 0, 0);
    for (row, step) in &plan {
        let done = match step {
            Step::Hold => continue,
            Step::Create => create(row, &target),
            Step::Update(current, _) => edit(row, current, &target),
        };
        if !done.status.success() {
            failed += 1;
            let stderr = String::from_utf8_lossy(&done.stderr);
            eprintln!("Failed: {}: {}", row.title, stderr.trim());
        } else if let Step::Update(..) = step {
            updated += 1;
        } else {
            created += 1;
        }
    }

    println!(
        "\nDone: {created} created, {updated} updated, {held} held, \
         {settled} up to date, {failed} failed"
    );
    if failed > 0 || held > 0 {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}
