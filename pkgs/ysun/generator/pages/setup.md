---
title: Nix Binary Cache
description: Nix Binary Cache
created: 2026-05-30
updated: 2026-05-30
hidden: true
---

## Pushing Paths

Using [Atelier](https://github.com/stepbrobd/atelier) in a public repository
that benefits the Nix or wider open source community? Please reach out! CI
runners OIDC push access may be granted to this cache, free for eligible
projects. Companies wanting a similar setup or general consulting are welcome to
reach out too.

## Public Key

Add these trusted public keys to your Nix/NixOS/nix-darwin configuration to
verify packages from this cache:

```txt
cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4=
```

## Option 1: Command Line (Temporary)

Use this cache for a single Nix command:

```shell
nix run \
  --substituters 'https://cache.ysun.co' \
  --trusted-public-keys 'cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4=' \
  github:stepbrobd/inc#nixvim
```

## Option 2: Nix Configuration (Persistent)

Add to your `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```txt
extra-substituters = https://cache.ysun.co
extra-trusted-public-keys = cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4=
```

## Option 3: NixOS/nix-darwin Configuration

Add to your `/etc/nixos/configuration.nix` or
`/etc/nix-darwin/configuration.nix`:

```nix
nix.settings = {
  extra-substituters = [ "https://cache.ysun.co" ];
  extra-trusted-public-keys = [ "cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4=" ];
};
```

## Option 4: Flake

Add to your `flake.nix`:

```nix
{
  nixConfig = {
    extra-substituters = [ "https://cache.ysun.co" ];
    extra-trusted-public-keys = [ "cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4=" ];
  };

  # ... rest of your flake
}
```

Note: Using `extra-*` settings will add this cache alongside the default
`cache.nixos.org` cache.

## Sponsors[^1]

[^1]: The views and content on this site are the author's own and do not
    represent those of the sponsors. Listing a sponsor does not imply their
    endorsement of this site, nor the author's endorsement of the sponsor.

**Thanks to [**Fastly**](https://www.fastly.com) for covering the CDN!**

![Fastly](/assets/static/img/logo-fastly.avif)

**Thanks to [**NetActuate**](https://netactuate.com) for providing
compute/transit!**

![NetActuate](/assets/static/img/logo-netactuate.avif)
