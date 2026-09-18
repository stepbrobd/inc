import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any, NoReturn, NotRequired, TypedDict, cast
from urllib import error, request

THINGS = "things"

QUERY = """query($userName:String){
  MediaListCollection(userName:$userName,type:ANIME,status:CURRENT){
    lists{entries{media{
      id
      siteUrl
      title{native english romaji}
      airingSchedule(notYetAired:true,perPage:50){nodes{episode airingAt}}
    }}}
  }
}"""

ANILIST = re.compile(r"https://anilist\.co/anime/\d+")
EPISODE = re.compile(r"(?:第(\d+)話|Episode (\d+))\s*$", re.IGNORECASE)
# kana and cjk, to mark an episode in the script the title is written in
CJK = re.compile(r"[\u3040-\u30ff\u4e00-\u9fff]")

Title = TypedDict(
    "Title", {"native": str | None, "english": str | None, "romaji": str | None}
)
Node = TypedDict("Node", {"episode": int, "airingAt": int})
Schedule = TypedDict("Schedule", {"nodes": list[Node]})
Media = TypedDict(
    "Media", {"id": int, "siteUrl": str, "title": Title, "airingSchedule": Schedule}
)
Entry = TypedDict("Entry", {"media": Media})
Group = TypedDict("Group", {"entries": list[Entry]})
Collection = TypedDict("Collection", {"lists": list[Group]})
Data = TypedDict("Data", {"MediaListCollection": Collection | None})
Message = TypedDict("Message", {"message": str})
Response = TypedDict(
    "Response",
    {"data": NotRequired[Data | None], "errors": NotRequired[list[Message] | None]},
)

Link = TypedDict("Link", {"id": str, "title": str})
Start = TypedDict("Start", {"scheduled_at": str | None, "reminder": str | None})
Flags = TypedDict("Flags", {"degraded": bool})
Task = TypedDict(
    "Task",
    {
        "id": str,
        "title": str,
        "status": str,
        "type": str,
        "notes": str | None,
        "project": Link | None,
        "area": Link | None,
        "start": Start,
        "flags": Flags,
    },
)
Area = TypedDict("Area", {"id": str, "title": str})


@dataclass(frozen=True)
class Episode:
    url: str
    number: int
    title: str
    when: str
    at: str


@dataclass(frozen=True)
class Existing:
    id: str
    title: str
    status: str
    when: str | None
    at: str
    degraded: bool
    container: "Container"


@dataclass(frozen=True)
class Container:
    id: str
    title: str
    kind: str

    @property
    def label(self) -> str:
        return f"{self.title} ({self.kind})" if self.kind else self.title


def fail(message: str) -> NoReturn:
    # stdout is block buffered off a terminal, so it would land after this
    sys.stdout.flush()
    print(message, file=sys.stderr)
    raise SystemExit(1)


def anilist(user: str) -> list[Media]:
    body = json.dumps({"query": QUERY, "variables": {"userName": user}}).encode()
    # anilist answers 403 to python-urllib's default agent
    headers = {
        "content-type": "application/json",
        "user-agent": "github:stepbrobd/inc",
    }
    payload: Response
    try:
        with request.urlopen(
            request.Request("https://graphql.anilist.co", body, headers), timeout=30
        ) as response:
            payload = json.load(response)
    except error.HTTPError as err:
        try:
            payload = json.load(err)
        except json.JSONDecodeError:
            fail(f"AniList answered HTTP {err.code}")
    except error.URLError as err:
        fail(f"AniList request failed: {err.reason}")
    except json.JSONDecodeError as err:
        fail(f"AniList answered with a body that is not JSON: {err}")

    messages = [item["message"] for item in payload.get("errors") or []]
    if messages:
        fail("AniList: " + "; ".join(messages))
    data = payload.get("data")
    collection = data["MediaListCollection"] if data else None
    if collection is None:
        fail(f"AniList returned no watchlist for user {user}")

    found: dict[int, Media] = {}
    for group in collection["lists"]:
        for entry in group["entries"]:
            found.setdefault(entry["media"]["id"], entry["media"])
    return list(found.values())


def episodes(media: list[Media]) -> list[Episode]:
    rows: list[Episode] = []
    for item in media:
        title = item["title"]
        name = title["native"] or title["romaji"] or title["english"] or "(untitled)"
        cjk = CJK.search(name) is not None
        for node in item["airingSchedule"]["nodes"]:
            number = node["episode"]
            mark = f"第{number}話" if cjk else f"Episode {number}"
            airs = datetime.fromtimestamp(node["airingAt"], UTC).astimezone()
            rows.append(
                Episode(
                    url=item["siteUrl"],
                    number=number,
                    title=f"{name} {mark}",
                    when=airs.strftime("%Y-%m-%d"),
                    at=airs.strftime("%H:%M"),
                )
            )
    return rows


def things(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run([THINGS, *args], capture_output=True, text=True, check=False)


def things_json(*args: str) -> Any:
    result = things("--json", *args)
    if result.returncode != 0:
        fail(f"The things {' '.join(args)} view failed: {result.stderr.strip()}")
    # the cli warns and serves its cache, which would read as missing to-dos
    if "Sync failed" in result.stderr:
        fail(f"Things could not reach Things Cloud: {result.stderr.strip()}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as err:
        fail(f"The things {' '.join(args)} view did not answer JSON: {err}")


def synced() -> dict[tuple[str, int], Existing]:
    index: dict[tuple[str, int], Existing] = {}
    for task in cast("list[Task]", things_json("find", "--any-status")):
        if task["type"] != "todo":
            continue
        url = ANILIST.fullmatch((task["notes"] or "").strip())
        number = EPISODE.search(task["title"])
        if not url or not number:
            continue
        # a day stamp is written at utc midnight so the day reads off the front
        scheduled = task["start"]["scheduled_at"]
        project, area = task["project"], task["area"]
        if project is not None:
            where = Container(project["id"], project["title"], "project")
        elif area is not None:
            where = Container(area["id"], area["title"], "area")
        else:
            where = Container("inbox", "Inbox", "")
        index[url.group(), int(number.group(1) or number.group(2))] = Existing(
            task["id"],
            task["title"],
            task["status"],
            scheduled[:10] if scheduled else None,
            task["start"]["reminder"] or "",
            task["flags"]["degraded"],
            where,
        )
    return index


def matching(items: list[Container], target: str) -> list[Container]:
    exact = [item for item in items if item.title.lower() == target.lower()]
    return exact or [item for item in items if item.id.startswith(target)]


def find_container(target: str) -> Container:
    if target.lower() == "inbox":
        return Container("inbox", "Inbox", "")
    known = [
        Container(area["id"], area["title"], "area")
        for area in cast("list[Area]", things_json("areas", "list"))
    ] + [
        Container(project["id"], project["title"], "project")
        for project in cast("list[Task]", things_json("projects", "list"))
    ]
    hits = matching(known, target)
    if not hits:
        fail(
            f"Container not found: {target}. Known: {', '.join(c.label for c in known)}"
        )
    if len(hits) > 1:
        matches = ", ".join(c.label for c in hits)
        fail(f"Container {target} is ambiguous, it matches: {matches}")
    return hits[0]


def matches(current: Existing, row: Episode, target: Container) -> bool:
    return (current.title, current.when, current.at, current.container.id) == (
        row.title,
        row.when,
        row.at,
        target.id,
    )


def drift(current: Existing, row: Episode, target: Container) -> str:
    parts = []
    if current.title != row.title:
        parts.append(f"titled {current.title}")
    if (current.when, current.at) != (row.when, row.at):
        parts.append(f"at {current.when or '-'} {current.at or '-'}")
    if current.container.id != target.id:
        parts.append(f"in {current.container.label}")
    return "was " + ", ".join(parts)


def edit(
    row: Episode, current: Existing, target: Container
) -> subprocess.CompletedProcess[str]:
    # --title= keeps clap from reading a leading hyphen as a flag
    args = ["edit", current.id, "--when", row.when, "--reminder", row.at]
    if current.title != row.title:
        args.append(f"--title={row.title}")
    if current.container.id != target.id:
        # --move inbox is refused alongside a day, clear keeps it and lands the same
        args += ["--move", "clear" if target.id == "inbox" else target.id]
    return things(*args)


def confirm(count: int) -> bool:
    if not sys.stdin.isatty():
        fail("Refusing to write without -y when there is no terminal to confirm at")
    return input(f"\nApply {count} changes? [y/N] ").strip().lower() in ("y", "yes")


def create(row: Episode, target: Container) -> subprocess.CompletedProcess[str]:
    return things(
        "new",
        "--in",
        target.id,
        "--when",
        row.when,
        "--reminder",
        row.at,
        "--notes",
        row.url,
        # -- guards a title that starts with a hyphen
        "--",
        row.title,
    )


class Formatter(argparse.HelpFormatter):
    def add_usage(self, usage, actions, groups, prefix="Usage: ") -> None:
        super().add_usage(usage, actions, groups, prefix)


class Parser(argparse.ArgumentParser):
    def error(self, message: str) -> NoReturn:
        self.print_usage(sys.stderr)
        self.exit(2, f"{self.prog}: {message[:1].upper()}{message[1:]}\n")


def parse_args() -> argparse.Namespace:
    parser = Parser(
        prog="aniremind",
        description="Sync an AniList watchlist into Things 3.",
        formatter_class=Formatter,
        add_help=False,
    )
    options = parser.add_argument_group("Options")
    options.add_argument(
        "-h", "--help", action="help", help="Show this help message and exit"
    )
    options.add_argument("-u", "--user", required=True, help="AniList username")
    options.add_argument(
        "-i",
        "--in",
        dest="container",
        required=True,
        metavar="CONTAINER",
        help="Where the to-dos go: inbox, or an area or project by title or id prefix",
    )
    options.add_argument(
        "-y", "--yes", action="store_true", help="Write without asking to confirm"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    now = datetime.now(UTC).astimezone()
    print(f"Timezone: {now.tzname()} {now.strftime('%z')}", flush=True)
    media = anilist(args.user)
    rows = sorted(episodes(media), key=lambda row: (row.when, row.at, row.title))
    print(f"AniList: {len(media)} shows, {len(rows)} unaired episodes", flush=True)
    target = find_container(args.container)
    print(f"Container: {target.label}", flush=True)
    index = synced()

    plan: list[tuple[str, Episode, Existing | None]] = []
    settled = 0
    for row in rows:
        current = index.get((row.url, row.number))
        if current is None:
            plan.append(("create", row, None))
        elif current.degraded:
            plan.append(("hold", row, current))
        elif current.status != "incomplete" or matches(current, row, target):
            settled += 1
        else:
            plan.append(("update", row, current))

    if plan:
        print()
    for kind, row, current in plan:
        line = f"{row.when} {row.at}  {row.title}"
        if kind == "hold":
            print(f"  hold    {line}  (degraded, things refuses to write it)")
        elif kind == "update" and current is not None:
            print(f"  update  {line}  ({drift(current, row, target)})")
        else:
            print(f"  create  {line}")

    writes = [item for item in plan if item[0] != "hold"]
    held = len(plan) - len(writes)
    if not writes:
        print(f"\nNothing to write, {held} held, {settled} up to date")
        return 1 if held else 0
    if not args.yes and not confirm(len(writes)):
        print("Nothing written")
        return 0

    created = updated = failed = 0
    for _kind, row, current in writes:
        done = create(row, target) if current is None else edit(row, current, target)
        if done.returncode != 0:
            failed += 1
            print(f"Failed: {row.title}: {done.stderr.strip()}", file=sys.stderr)
        elif current is None:
            created += 1
        else:
            updated += 1

    print(
        f"\nDone: {created} created, {updated} updated, {held} held, "
        f"{settled} up to date, {failed} failed"
    )
    return 1 if failed or held else 0


if __name__ == "__main__":
    raise SystemExit(main())
