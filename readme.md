# The second largest Nix monorepo

Maybe the title isn't that clickbaity? As of this commit there are about 15k
lines of Nix...

I have strong opinions on how Nix configurations should be structured and
deployed. Most "conventions" in the ecosystem (snowfall, flake-utils, dendritic
etc.) encode incidental complexity as community norms. They trade structural
clarity for framework overhead, and I personally don't think the tradeoff is
worth it.

The patterns here are quite minimal (I think): fs based discovery, library
extension, and thin abstraction over module system to preserve/enhance
compositional reasoning. Every host's configuration is determined by blueprint
metadata, set of modules selected by its group, and its host entrypoint.

If you want to reuse any of this, the configs have fairly straightforward looks
and should just work if you fork and get rid of all modules, hosts and user
configs.

## Evaluation order

[`autopilot`](https://github.com/stepbrobd/autopilot) is a thin wrapper around
`flake-parts` that provides directory structure based autoloading for `lib`,
`pkgs`, and flake-parts modules. Similar to
[`blueprint`](https://github.com/numtide/blueprint) or
[`import-tree`](https://github.com/vic/import-tree), but I wrote my own because
I wanted specific behaviors around library extension and package scoping.

Evaluation order:

**`lib`**: autopilot loads every `.nix` file under `lib/`, converts filenames
from kebab-case to camelCase, and merges them into a single fixpoint that
extends `nixpkgs.lib`. User-defined functions shadow nixpkgs builtins on name
collision. Extension libraries (colmena, nix-darwin, flake-parts, etc.) are
merged before user functions, so user definitions take final precedence.

**`pkgs`**: for each system, autopilot calls
`import nixpkgs { system; config; overlays; }` where overlays include the local
overlay (from `pkgs/`) and external overlays. The resulting `pkgs` is exposed to
all flake-parts `perSystem` scopes.

**`flake-parts` eval**: modules under `modules/flake/` are auto-discovered and
loaded. Each receives the extended `lib`, `inputs`, and `getSystem` in scope.

## Library extension

Everything in `lib/` is available everywhere: in NixOS/darwin modules via
`importApplyWithArgs`, in flake-parts modules via `lib` argument, and in package
definitions through overlay. Everything in `lib/` will automatically override
`nixpkgs.lib` or other extensions if there are naming conflicts, so it is easy
to modify standard library behaviors.

The `importApplyWithArgs` (basically wrapped `importApply`) function handles
injection into NixOS/darwin/home-manager modules without requiring `specialArgs`
for every custom binding. It inspects the module's function signature at import
time: if any parameter names intersect with the provided static arguments (e.g.
`inputs`, `lib`), it partially applies them before the module system sees the
module. If the imported file is a plain attrset or a function whose parameters
do not match, it passes through unchanged.

This means external consumers of these modules are never forced to provide
arguments they do not define. The injection is structurally invisible to the
module system. This solves the same problem as dendritic pattern (declaring
everything as flake-parts modules) without losing the structural scoping that
the module system provides.

## Package overlay

The `importPackagesTree` function is similar to library extension. It does
directory structure based auto discovery to define, override (for both
derivations and scopes even plain attrsets) through recursive traversal of
`pkgs/`. The overlay is injected by autopilot alongside external overlays.

The traversal handles three cases based on directory structure:

**Standalone packages**: directories with `default.nix` are package definitions.
It is called with `callPackageWith` against the current package set. The local
definition always takes precedence over nixpkgs, so placing
`pkgs/alacritty/default.nix` overrides `pkgs.alacritty` globally. The function
signature receives the full package scope, so standard nixpkgs dependencies
(e.g. `fetchFromGitHub`, `stdenv`) resolve naturally:

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
inside that scope, receiving scope-level fixpoint bindings (`<scopeName>Final`,
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
packages are exported as nested attrsets. The `packages` flake output aliases
`legacyPackages` directly, since the standard `packages` output does not support
nested scopes (should we "fix" this?).

## Blueprint

`lib.blueprint` has all the metadata. It defines hosts, users, services, network
prefixes, and Tailscale/ranet configuration as plain attrsets. Each host
declaration (`lib/blueprint/hosts/<name>/default.nix`) specifies platform, OS,
provider, type, tags, etc. Auto generated tags include the OS, platform,
provider, and type, so for example `lib.blueprint.hosts.walberla.tags` evaluates
to
`["nixos" "x86_64-linux" "hetzner" "server" "routee" "glance" "golink" "kanidm" "ranet"]`.

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
  `colmena apply -t server`, `colmena apply -t hyprland`, etc.
- **terranix**: Cloudflare resources (DNS zones, reverse DNS, buckets, SSO
  settings) and Tailscale DNS entries are derived from blueprint host metadata.
- **Prometheus**: monitoring targets are generated from blueprint service
  declarations.
- Maybe some other shit I don't really remember...

## Deployment

Currently all hosts (10 NixOS servers, 2 NixOS laptops, 1 macbook on nix-darwin)
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
with overlays), and `deployment.systemType` is set from the group's `os` field.
`nixosConfigurations` and `darwinConfigurations` flake outputs are extracted
from `colmenaHive.nodes` by filtering on each node's `class` attribute.

Darwin support comes from my
[patched Colmena fork](https://github.com/stepbrobd/colmena/tree/detached) that
adds `evalDarwinNode`, `deployment.systemType`, and `meta.nix-darwin` to the
hive evaluator based on
[colmena#319](https://github.com/zhaofengli/colmena/pull/319). The fork also
includes detached activation for NixOS nodes (activation launched via
`systemd-run` so it survives SSH drops during network/firewall restarts).

## Networking

Those servers in here run my personal autonomous system. Some nodes maintain BGP
sessions with their providers and originate prefixes; the rest are routee nodes
that receive traffic via the internal mesh.

The internal mesh is migrating from Tailscale (wg mesh) to
[ranet](https://github.com/NickCao/ranet) (IPsec mesh). Tailscale consumes the
entire CGNAT range with no way to preserve source IP addresses across multiple
hops, does not support multicast (ruling out protocols like babel), and upstream
has shown no interest in addressing these limitations
([tailscale#18781](https://github.com/tailscale/tailscale/pull/18781) where the
original issues have been stuck for years,
[lobste.rs discussion on my hard patch writup](https://lobste.rs/s/2pi9sn/de_escalating_tailscale_cgnat_conflict)).

I gave a talk on running routing experiment and overlay network with NixOS at
NixCon 2025:
[Internet scale routing with NixOS](https://talks.nixcon.org/nixcon-2025/talk/7YWTUC/)
([YouTube](https://youtu.be/ebZJLKc80oE),
[media.ccc.de](https://media.ccc.de/v/nixcon2025-56390-internet-scale-routing),
[repo](https://github.com/stepbrobd/router)).

## Repo management

Everything else in this repo is declarative, so why not git repos too?

[Miroir](https://github.com/stepbrobd/miroir) is a CLI tool (and index daemon)
that manages repos across multiple git forges from a single TOML config
([`repos/config.toml`](repos/config.toml)). Each repo declares its description,
visibility, and archive status. Each platform declares a forge domain and
username. Miroir converges the declared state onto all configured forges:
creating repos that don't exist, updating metadata on ones that do, and
archiving repos marked `archived = true`.

The practical motivation is multi-forge redundancy. All repos are mirrored to
GitHub, GitLab, Codeberg, and SourceHut so that no single forge going down (or
going sideways? I'm looking at you GitHub?) loses anything. `miroir push -a`
concurrently pushes to every configured remote, `miroir init -a` clones
everything onto a fresh machine with all remotes already wired up.

The same config also drives a server side code search engine. The NixOS module
([`modules/nixos/neogrok.nix`](modules/nixos/neogrok.nix)) imports
`repos/config.toml`, overlays server-specific settings (listen address, SSH key
from sops), and runs `miroir index` as a systemd service. miroir periodically
fetches and indexes every declared repo into
[zoekt](https://github.com/sourcegraph/zoekt), served through
[neogrok](https://github.com/isker/neogrok) behind Caddy with SSO at
[`grep.ysun.co`](https://grep.ysun.co).

Forge metadata sync currently supports GitHub, GitLab (official or self-hosted),
Codeberg (and derivative Forgejo/Gitea instances), and SourceHut. This also
doubles as a migration tool if you want to jump ship from one forge to another.

See more on
[NixOS Discourse](https://discourse.nixos.org/t/declare-and-manage-your-repositories-on-multiple-platforms-code-search-engine/76332).

## License

The contents inside this repository, excluding all submodules, are licensed
under the [MIT License](license.txt). Third-party file(s) and/or code(s) are
subject to their original term(s) and/or license(s).
