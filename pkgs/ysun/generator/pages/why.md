---
title: The second largest Nix monorepo
description: How to manage the second largest Nix monorepo? I'll cover how I setup a weird configuration structure that allowed me to override arbitrary nixpkgs.lib functions and any nix packages.
created: 2026-03-03
updated: 2026-09-14
---

So... First of all, clickbait title ;) I'm certain there are larger Nix monorepo
than what I have here, but still, 17k LoC of Nix (at the time of writing) for
config is still kinda insane!

## Philosophy

I want MY library functions and package definitions to have the highest
priority, and be made available in whichever file. This means that, in
`flake-parts` flake modules, in overridden library scope, in NixOS/Darwin
modules, modules for Terranix, package definitions, etc., when I refer to `pkgs`
or `lib`, I would want to have the version with my overlays applied + whatever
extensions I injected.

To make this possible, the evaluation must start at library functions, and
ideally, everything in `lib` should be pure (i.e. no side effects), and depends
only on `builtins`, `nixpkgs.lib`, and the extensions I imported through
`autopilot`.

## Autopilot

[Autopilot](https://github.com/stepbrobd/autopilot) is a thin `flake-parts`
wrapper that's talared to my taste of how a "nix flake" (damn I feel cringe
writing this, for stable Nix users, I don't care what your think how Nix should
work, I pick my own shit and I picked the one that suits me the best) should
look like.

In the repo, I wrote:

> Autopilot evaluates user defined library before letting `flake-parts`
> takeover. User defined library (including extensions) will be passed as
> `specialArgs` to `flake-parts`, i.e. `lib` will be made available to
> `flake-parts` modules and `perSystem` configurations.

And a sample `flake.nix` (with `inputs` stripped to save some space):

```nix
{
  outputs = inputs: inputs.autopilot.lib.mkFlake {
    inherit inputs;

    autopilot = {
      lib = {
        path = ./lib;
        excludes = [ ];
        extender = inputs.nixpkgs.lib;
        extensions = with inputs; [ autopilot.lib parts.lib ];
      };

      nixpkgs = {
        config.allowUnfree = true;
        overlays = [ ];
        instances = [
          { pkgs = inputs.nixpkgs; }
          { unstable = inputs.unstable; }
        ];
      };

      parts = { path = ./modules/flake; excludes = [ ]; };
    };
  } { systems = import inputs.systems; };
}
```

In the simplest case, I want the repo to look like this:

```
- flake.nix
- lib
  - add-one.nix
- modules
  - flake
    - formatter.nix
```

Where:

```nix
# ./lib/add-one.nix # will be made available as `lib.addOne`
{ lib }: x: x + 1
```

```nix
# ./modules/flake/formatter.nix
{
  perSystem = { unstable, ... }: {
    formatter = unstable.nixpkgs-fmt;
  };
}
```

The above is from the users' perspective, under the hood:

## Fixedpoint?

The whole thing is one `extend` call in autopilot with a specific merge order:

```nix
finalLib = cfg.lib.extender.extend (final: prev: mergeAttrsList (
  # builtins minus whatever's already in the extender
  [ (removeAttrs builtins (intersectLists
      (attrNames cfg.lib.extender)
      (attrNames builtins))) ]
  # user provided extensions e.g. colmena.lib, parts.lib, terranix.lib, ...
  ++ cfg.lib.extensions
  # user's own ./lib/*.nix, loaded with `{ lib = final; }`
  ++ [ (loadAll {
        dir = cfg.lib.path;
        transformer = kebabToCamel;
        args = { lib = final; };
      }) ]
));
```

`mergeAttrsList` precedence goes `builtins` and `nixpkgs.lib` (the default
extender) < extensions < my stuff, e.g. if user defined a `lib/map.nix` that
does something weird, the newly defined function will shadow `builtins.map` and
`nixpkgs.lib.map`.

Note that every file under `./lib/` is loaded with `{ lib = final; }`, not
`{ lib = prev; }`. This way `lib/has-tag.nix` in my actual config can reach into
`lib.blueprint.hosts.${hostName}` even though `lib/blueprint/default.nix` is a
sibling file loaded in the same pass.

Once `finalLib` exists, autopilot glues it onto `flake-parts`'s `specialArgs`:

```nix
finalArgs = recursiveUpdate args { specialArgs.lib = finalLib; };
```

From this point on, every `{ lib, ... }:` inside any flake-parts module or
`perSystem` or via `importApplyWithArgs` (to be covered below) (i.e. every
NixOS/darwin/home-manager/ terranix module) gets _my_ `lib` instead of whatever
downstream module system wanted to hand me.

## How to use the library extension everywhere

Since autopilot will only give you the extended `lib` in flake-parts modules,
"functional" (meaning the files generating system or user configurations, or
packages to be exposed) still doesn't have the extended functions.

The `importApplyWithArgs` (basically wrapped `importApply`) function handles
injection into NixOS/darwin/home-manager modules without requiring specialArgs
for every custom binding. It inspects the module's function signature at import
time. If any parameter names intersect with the provided static arguments (e.g.
`inputs`, `lib`), it partially applies them before the module system sees the
module. If the imported file is a plain attrset or a function whose parameters
do not match, it passes through unchanged.

This would also mean that external consumers of these modules are never forced
to provide arguments they do not define (the injection is structurally invisible
to the module system). This solves the same problem as "dendritic pattern"
(declaring everything as flake-parts modules) without losing the structural
scoping that the module system provides.

## Package overlay

I have a LOT of custom packages, some of them are just used to temporarily
unbreak build where no PR exist in nixpkgs or just merged and hasn't hit the
branch I'm tracking. I want to have all my custom packages including scopes to
be directly injected into all `pkgs` occurrences I use.

The `importPackagesTree` function is similar to the above mentioned library
extension. It does directory structure based auto discovery to define, override
(for both derivations and scopes even plain attrsets) through recursive
traversal of `pkgs/`. The overlay is injected by autopilot alongside external
overlays (this is why I mentioned evaluation must start from the library
functions).

The traversal handles three cases based on directory structure:

**Standalone packages**: directories with `default.nix` are package definitions.
It is called with `callPackageWith` against the current package set. Local
definition always takes precedence over nixpkgs, e.g. placing
`pkgs/alacritty/default.nix` would override `pkgs.alacritty` globally. Also note
that in my implementation, the scoped import function signature receives the
full nixpkgs package scope, making standard nixpkgs dependencies (e.g.
`fetchFromGitHub`, `stdenv`) resolve naturally (even inside nested scopes, see
below):

```
pkgs/
  alacritty/
    default.nix # overrides pkgs.alacritty
  bird3/
    default.nix # overrides pkgs.bird3
```

**Scope override**: directories without `default.nix` whose names match existing
nixpkgs scope names (i.e. an attrset with `overrideScope` or `extend`) will
trigger recursive scope override. Child directories become package overrides
inside that scope, receiving scope level fixpoint bindings (`<scopeName>Final`,
`<scopeName>Prev`) alongside the root level `pkgsFinal`/`pkgsPrev`. For example,
`pkgs/ocamlPackages/omd/default.nix` calls `ocamlPackages.overrideScope` and the
`omd` package inside receives `buildDunePackage` from the OCaml scope:

```
pkgs/
  ocamlPackages/  # no default.nix, matches pkgs.ocamlPackages
    omd/
      default.nix # receives buildDunePackage, ocamlPackagesFinal, etc.
    yocaml/
      default.nix
```

**Scope creation**: directories without `default.nix` that do not match any
existing nixpkgs scopes but contain child directories with `default.nix` creates
a new scope via `makeScope`.

The `localPackagesFrom` function mirrors this traversal to extract only locally
defined packages for the `legacyPackages` flake output, filtering the full
`pkgs` set to entries whose names correspond to directories in `pkgs/`. Scoped
packages are exported as nested attrsets.

Note that the `packages` flake output will not work as the output schema does
not support nested scopes like `packages.x86_64-linux.<scope>.<package>` (should
we "fix" this?).

## Blueprint

I've made `lib.blueprint` to include all the metadata including hosts, users,
services, network prefixes, and SDWAN/SDLAN configuration in plain attrsets.
Each host declaration (`lib/blueprint/hosts/<name>/default.nix`) specifies OS
(NixOS ofc), provider, type, tags, etc. Auto generated tags passed to
[Colmena](https://github.com/nix-community/colmena) will contain the OS,
provider, and type. For example `lib.blueprint.hosts.walberla.tags` evaluates to
`["nixos" "hetzner" "server" "routee" "glance" "kanidm" "ranet"]`.

Most NixOS service modules use `lib.hasTag` to conditionally enable themselves:

```nix
{ lib, ... }:
{ config, ... }:
{ services.glance.enable = lib.hasTag config.networking.hostName "glance"; }
```

This keeps service assignment declarative and centralized in blueprint rather
than scattered across per-host entrypoints. Adding a service to a host is
literally just a one line tag addition.

Blueprint data is also consumed by:

- **Colmena**: `deployment.tags` are populated from blueprint, enabling
  `colmena apply --on @server`, `colmena apply --on framework,xps`, etc.
- **terranix**: Resources like DNS zones, reverse DNS, buckets, SSO settings and
  Tailscale DNS entries bound to my custom domain are derived from blueprint
  host metadata.
- **Prometheus**: monitoring targets are generated from blueprint service
  declarations.
- Maybe some other shit I don't really remember...

## Deployment

Currently all hosts (16 NixOS servers, 2 NixOS laptops, 1 MacBook on nix-darwin)
are managed through Colmena. The `mkColmena` function accepts a list of host
groups, each specifying OS, platform, modules, users, and host names:

```nix
mkColmena {
  inherit inputs specialArgs getSystem;
  nixpkgs = inputs.nixpkgs;
  nix-darwin = inputs.darwin;
  hosts = [
    { os = "nixos";  platform = "x86_64-linux";   modules = serverModules; users = serverUsers; names = [ "walberla" "butte" ... ]; }
    { os = "nixos";  platform = "aarch64-linux";  modules = serverModules; users = serverUsers; names = [ "isere" ]; }
    { os = "nixos";  platform = "x86_64-linux";   modules = laptopModules; users = laptopUsers; names = [ "framework" ]; }
    { os = "darwin"; platform = "aarch64-darwin"; modules = darwinModules; users = darwinUsers; names = [ "macbook" ]; }
  ];
}
```

Internally the groups are flattened into a per-host config map. Each host gets
its `nodeNixpkgs` from `getSystem platform` (the autopilot instantiated pkgs
with overlays mentioned above), and `deployment.systemType` is set from the
group's `os` field. `nixosConfigurations` and `darwinConfigurations` flake
outputs are extracted from `colmenaHive.nodes` by filtering on each node's
`class` attribute.

Darwin support comes from my
[patched Colmena fork](https://github.com/stepbrobd/colmena) that adds
`evalDarwinNode`, `deployment.systemType`, and `meta.nix-darwin` to the hive
evaluator based on
[colmena#319](https://github.com/zhaofengli/colmena/pull/319). The fork also
includes detached activation for NixOS nodes (activation launched via
`systemd-run` so it survives SSH drops during network/firewall restarts).

## Networking

Those servers in here run my personal autonomous system. Some nodes maintain BGP
sessions with upstream providers and originate prefixes, the rest are routee
nodes that receive traffic via the internal mesh.

The internal mesh migrated from Tailscale (WireGuard mesh) to
[ranet](https://github.com/NickCao/ranet) (IPsec mesh). Tailscale consumes the
entire CGNAT range with no way to preserve source IP addresses across multiple
hops, does not support multicast (ruling out protocols like babel), and upstream
has shown no interest in addressing these limitations
([tailscale#18781](https://github.com/tailscale/tailscale/pull/18781) where the
original issues have been stuck for years,
[lobste.rs discussion on my hard patch writup](https://lobste.rs/s/2pi9sn/de_escalating_tailscale_cgnat_conflict)).
Direct link to the post [here](/tscgnat).

I've also given a talk on running routing experiment and overlay network with
NixOS at NixCon 2025:
[Internet scale routing with NixOS](https://talks.nixcon.org/nixcon-2025/talk/7YWTUC/)
([YouTube](https://youtu.be/ebZJLKc80oE),
[media.ccc.de](https://media.ccc.de/v/nixcon2025-56390-internet-scale-routing),
[repo](https://github.com/stepbrobd/router)).

## Repo management

Everything else in this repo is declarative, so why not git repos too?

[Miroir](https://github.com/stepbrobd/miroir) (see also [here](/miroir)) is a
CLI tool (and index daemon) that manages repos across multiple git forges from a
single TOML config
([`repos/config.toml`](https://github.com/stepbrobd/inc/blob/master/repos/config.toml)).
Each repo declares its description, visibility, and archive status. Each
platform declares a forge domain and username. Miroir converges the declared
state onto all configured forges: creating repos that don't exist, updating
metadata on ones that do, and archiving repos marked `archived = true`.

The practical motivation is multi-forge redundancy. All repos are mirrored to
GitHub, GitLab, Codeberg, and SourceHut so that no single forge going down (or
going sideways? I'm looking at you GitHub?) loses anything. `miroir push -a`
concurrently pushes to every configured remote, `miroir init -a` clones
everything onto a fresh machine with all remotes already wired up.

The same config also drives a server side code search engine.
[The NixOS module](https://github.com/stepbrobd/inc/blob/master/modules/nixos/neogrok.nix)
imports `repos/config.toml`, overlays server-specific settings (listen address,
SSH key from sops), and runs `miroir index` as a systemd service. Miroir
periodically fetches and indexes every declared repo into
[zoekt](https://github.com/sourcegraph/zoekt), served through
[neogrok](https://github.com/isker/neogrok) behind Caddy with SSO at
[`grep.ysun.co`](https://grep.ysun.co).

Forge metadata sync currently supports GitHub, GitLab (official or self-hosted),
Codeberg (and derivative Forgejo/Gitea instances), and SourceHut. This also
doubles as a migration tool if you want to jump ship from one forge to another.

See more on
[NixOS Discourse](https://discourse.nixos.org/t/declare-and-manage-your-repositories-on-multiple-platforms-code-search-engine/76332).
