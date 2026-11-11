---
title: Conform to XDG spec please
description: Tired of cluttered home directory? A call to action to follow the XDG Base Directory Specification
created: 2023-04-26
updated: 2026-09-14
---

The
[XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
is not some new thing, it's been around for a while. Writing a new project? Use
it. Updating an old project? Use it. It's not hard to implement, it's not hard
to use. Don't just throw a `.<app>` to user home directory, or be like `~/go`.

- [HackerNews Discussion](https://news.ycombinator.com/item?id=35283967)
  (2023-03)
- [Use the XDG Base Directory Specification!](https://xdgbasedirectoryspecification.com)
  ([@hyperupcall](https://github.com/hyperupcall))
- [XDG-Ninja](https://github.com/b3nj5m1n/xdg-ninja)([@b3nj5m1n](https://github.com/b3nj5m1n))

It should be very easy to implement even without a library. But if you are lazy:

- [Deno/Node Implementation](https://github.com/srstevenson/xdg-base-dirs)
  ([@srstevenson](https://github.com/srstevenson))
- [Go Implementation](https://github.com/adrg/xdg)
  ([@adrg](https://github.com/adrg))
- [Rust Implementation](https://github.com/whitequark/rust-xdg)
  ([@whitequark](https://github.com/whitequark))
