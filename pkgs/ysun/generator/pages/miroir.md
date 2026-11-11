---
title: Miroir
description: Repo manager wannabe?
created: 2025-10-03
updated: 2026-03-08
metas:
  go-import: ysun.co/miroir git https://github.com/stepbrobd/miroir.git
  go-source: ysun.co/miroir https://github.com/stepbrobd/miroir https://github.com/stepbrobd/miroir/tree/master{/dir} https://github.com/stepbrobd/miroir/blob/master{/dir}/{file}#L{line}
---

[Miroir](https://github.com/stepbrobd/miroir) exists because managing repos
across multiple forges by hand is tedious. I want all my repos declared in one
place, then synced to GitHub, GitLab, Forgejo, SourceHut, and whatever else I
happen to use. Creating repos, updating descriptions, flipping private/public,
changing archive status, and keeping metadata in sync should be a CLI workflow,
not a bunch of clicking around.

Given that I am already too deep into the Nix ecosystem, my brain is now
permanently convinced that everything in life should be declarative (even git
repos???).

This also doubles as the plumbing for my own code search setup. Since all repos
are declared already, miroir can periodically mirror and index them with
[Zoekt](https://github.com/sourcegraph/zoekt) as a library, then serve the
shards through [Neogrok](https://github.com/isker/neogrok). GitHub code search
is good for public code, but sometimes it is stale or slow. This setup is
faster, easier to maintain, and works for my own private repos too.

This repo originally started in OCaml because I wanted to learn and get used to
the [Eio](https://github.com/ocaml-multicore/eio) direct style concurrency
model. I eventually decided that was probably too much pain for what is, at the
end of the day, a pretty simple workflow. Around the same time I got 6mo Claude
Max 20x through Anthropic's open source sponsorship program and
[wanted to try it out](https://bsky.app/profile/stepbrobd.com/post/3mg6qllnlf22z)...
So here we are... Do note that a large chunk of the code was written by LLM
after commit
[`cabbdc4`](https://github.com/stepbrobd/miroir/commit/cabbdc468d421abd25f9869ef36967039903c38f).

The config is intentionally simple (my real config is like 400 lines of toml at
the time of writing this tho):

```toml
[platform.github]
origin = true
domain = "github.com"
user = "stepbrobd"

[repo."miroir"]
description = "repo manager wannabe?"
visibility = "public"
archived = false
```

You can see the search instance at <https://grep.ysun.co> (behind my SSO), and I
posted a bit about it on
[Bluesky](https://bsky.app/profile/stepbrobd.com/post/3mggadgw6ec2o).
