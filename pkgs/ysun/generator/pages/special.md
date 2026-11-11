---
title: "`specialArgs` considered harmful"
description: "Why `specialArgs` in `lib.evalModules` is considered an antipattern."
created: 2026-09-28
updated: 2026-10-07
---

> I'm writing this on my flight from KRK to LYS after Wizz Air fucked me in the
> ass... I briefly went over this yesterday (and the day before) at
> [NixCon 2026](https://2026.nixcon.org) in my lightning talks (a normal one and
> a spontaneous one). The purpose of this article is to better articulate myself
> in addition to my very terrible verbal explanation. [This](/why) is also
> related.

I read a lot of code (especially Nix), and I've helped quite some people getting
their first NixOS installation working. Normally, users want unified theming
across login manager, desktop environment, lock screen, etc., and they would opt
to pin a styling dependency in `inputs`.

To pass them around in NixOS/nix-darwin/home-manager eval context, `inputs` are
usually injected into `specialArgs` (or `extraSpecialArgs`, or similar) so that
all modules have an `inputs` argument where additional `options` can be used
(you also get `inputs.self` fixed point ofc).

Once a config repo gets big enough (10+ machines or some hosts are shared),
`specialArgs` are not only used to pass `inputs` around module eval context,
e.g. custom helper functions, static data, and maybe some other less common
arguments are injected as well, making the modules unshareable (or at least
making it hard to copy-pasta).

## `specialArgs` is not portable

For example (you can copy the code below to a throwaway directory and try it
out):

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    inputs@{ self, nixpkgs }:
    {
      nixosModules.version = { inputs, ... }: {
        # DO NOT DO THIS THIS IS JUST AN EXAMPLE
        # read `system.stateVersion` docs very carefully
        system.stateVersion = with inputs.nixpkgs.lib; versions.majorMinor version;
      };

      nixosConfigurations.works = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [ self.nixosModules.version ];
      };

      nixosConfigurations.breaks = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModules.version ];
      };
    };
}
```

You'll get:

```console
$ nix eval --raw .#nixosConfigurations.works.config.system.stateVersion
26.11
$ nix eval --raw .#nixosConfigurations.breaks.config.system.stateVersion
error:
      ...
      ... while evaluating the module argument `inputs' in ":anon-2117:anon-1":
      ... noting that argument `inputs` is not externally provided, so querying `_module.args` instead, requiring `config`
       (stack trace truncated; use '--show-trace' to show the full, detailed trace)
       error: attribute 'inputs' missing
```

Same idea applies to other arbitrary shareable modules.

This is one of the most common issues with the current "Nix Flakes" ecosystem.
Now maybe you are convinced using `specialArgs` is a bad idea but how can we
address this?

## "Curried modules"?

There are sooooo many ways to approach this, but the general idea is to apply
the special module arguments before `lib.evalModules` consumes the module
implementation.

For example:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    inputs@{ self, nixpkgs }:
    {
      nixosModules.version =
        (
          { inputs, ... }: # special args
          { ... }: # normal NixOS module args
          {
            # actual implementation
            system.stateVersion = with inputs.nixpkgs.lib; versions.majorMinor version;
          }
        )
          { inherit inputs; }; # consume the first argument

      nixosConfigurations.works = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [ self.nixosModules.version ];
      };

      nixosConfigurations.breaks = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModules.version ];
      };
    };
}
```

Yeah now both eval commands above work. But yall will most definitely argue this
shit is too ugly blah blah blah.

I thought so too, maybe 2 years ago? I addressed it.

To make it "look prettier", yall should first understand how/why modules
computed with `lib.evalModules` can either have 0 arguments (plain attrset) or 1
argument (`{ config, options, pkgs, lib, ... }` and some other less used named
args):

```nix
# nixpkgs/lib/modules.nix (2026-09-27) under `evalModules` implementation

# This function takes an empty attrset as an argument.
# It could theoretically be replaced with its body,
# but such a binding is avoided to allow for earlier garbage collection.
doCollect =
  { }:
  collectModules class (specialArgs.modulesPath or "") (regularModules ++ [ internalModule ]) (
    { /* truncated */ }
    // specialArgs
  );

# collectModules :: (class: String) -> (modulesPath: String) -> (modules: [ Module ]) -> (args: Attrs) -> ModulesTree
#
# Collects all modules recursively through `import` statements, filtering out
# all modules in disabledModules.
collectModules =
  class:
  let
    # Like unifyModuleSyntax, but also imports paths and calls functions if necessary
    loadModule =
      args: fallbackFile: fallbackKey: m:
      if isFunction m then
        unifyModuleSyntax fallbackFile fallbackKey (applyModuleArgs fallbackKey m args)
      else if isAttrs m then
        if m._type or "module" == "module" then
          unifyModuleSyntax fallbackFile fallbackKey m
        else if m._type == "if" || m._type == "override" then
          loadModule args fallbackFile fallbackKey { config = m; }
        else
          throw ... # truncated
      else if isList m then
        ... # truncated
      else
        unifyModuleSyntax (toString m) (toString m) (
          applyModuleArgsIfFunction (toString m) (import m) args
        );
    ... # truncated
  ... # mostly related to filtering disabled modules, sanity checks, and graph construction
```

`loadModule` calls a module in with "function shape" (again, it should look
something like `{ lib, ... }: { ... }`), through `applyModuleArgs` with `args`,
which contains standard arguments (`lib`, `config`, `options`, ...) merged with
user specified `specialArgs`.

If the module is a plain attrset, it will be used as is.

Very informally, the invariant is that, whatever passed to `modules` list
parameter to `lib.evalModules` has to be a "module". Anything that happened to
the "module" shaped file or lambda before `lib.evalModules` is invisible to the
module evaluation context. In this sense, a curried module is nothing more than
a function we've already called.

`applyModuleArgs` is also where the error in the first example comes from:

```nix
# nixpkgs/lib/modules.nix (2026-10-07) under `applyModuleArgs`
extraArgs = mapAttrs (
  name: _:
  addErrorContext ''while evaluating the module argument `${name}' in "${key}":'' (
    args.${name} or (addErrorContext
      "noting that argument `${name}` is not externally provided, so querying `_module.args` instead, requiring `config`"
      config._module.args.${name}
    )
  )
) (functionArgs f);
```

Every argument in the function's pattern (`functionArgs f`) is looked up in
`args` first (which is where `specialArgs` is injected into) and then in
`config._module.args`. A module that asks for `inputs` in args will only works
if whoever coded it (or downstream users) put `inputs` in one of the two.

### `importApply`

Moving the curried module to a file and calling
`import ./version.nix { inherit inputs; }` will works as well, but error
messages lose the file location, since `import` only returns the expression. In
nixpkgs, we've had `lib.modules.importApply` to solve this "problem" since
[nixpkgs#230588](https://github.com/nixos/nixpkgs/pull/230588) (also in
`flake-parts`).

```nix
# version.nix
{ inputs }: # special args
{ ... }: # normal NixOS module args
{
  system.stateVersion = with inputs.nixpkgs.lib; versions.majorMinor version;
}
```

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    inputs@{ self, nixpkgs }:
    {
      nixosModules.version = nixpkgs.lib.modules.importApply ./version.nix { inherit inputs; };

      nixosConfigurations.works = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModules.version ];
      };
    };
}
```

Very briefly, [`importApply`](https://noogle.dev/f/lib/modules/importApply)
imports the module, applies the user passed arguments, and wraps the result so
errors point at `version.nix`.

### `importApplyWithArgs`

I don't want to write that call for every module in my config, so my loader
scans every file under a module directory with
[`importApplyWithArgs`](https://github.com/stepbrobd/inc/blob/master/lib/import-apply-with-args.nix)
and invoke it with `{ inherit inputs lib; }`, where `lib` is my extended
`nixpkgs.lib` (see [this](/why)).

`importApplyWithArgs` inspects the outer arguments of each file before module
system computation:

- When the pattern (the first argument of my module implementation files) names
  one of the static arguments, and the static arguments cover every argument in
  it without a default, the file is applied, e.g.
  `{ inputs, lib, ... }: { config, ... }: { ... }`.
- A non-pattern lambda (`args: ...`) is probed with `f { }` and applied if that
  returns another function.
- Anything else, a plain attrset or a normal `{ config, lib, pkgs, ... }:`
  module, passes through untouched and inherits the arguments from the module
  system.

This means external consumers (like whoever is mentally unstable enough to use
my code) of these modules are never forced to provide arguments they do not
define (the injection is structurally invisible to the module system as
discussed above).

Using a pattern like this would also solves the same problem as "dendritic
pattern" (declaring everything as flake-parts modules) without losing the
structural scoping that the module system provides (thanks
[Matt](https://github.com/mattsturgeon)!).

### Deduplication

The module system collects each `key` once. A module imported by path gets the
path as its key, which is why importing `./foo.nix` twice is harmless and
`disabledModules = [ ./foo.nix ]` would work. THIS IS VERY IMPORTANT, note that
a function or an attrset will get an anonymous key, and the same value imported
twice becomes two modules:

```console
nix-repl> :lf nixpkgs
nix-repl> m = { lib, ... }: { options.b = lib.mkOption { default = "x"; }; }
nix-repl> :p (lib.evalModules { modules = [ m m ]; }).config
error:
       ...
       error: The option `b' in `<unknown-file>' is already declared in `<unknown-file>'.
nix-repl> :p (lib.evalModules { modules = [ { key = "m"; imports = [ m ]; } { key = "m"; imports = [ m ]; } ]; }).config
{ b = "x"; }
```

In `setDefaultModuleLocation` (which `importApply` uses), it sets `_file` but
not `key`, which leaves every curried module anonymous. Imported twice it is
declared twice, and `disabledModules` cannot name it. Well, this is very bad as
you cal already tell from the above REPL snippet...

```nix
# https://github.com/stepbrobd/inc/commit/7170c5279142d3bc6ed1c524e93effe132a55ab3
{
  # was using https://noogle.dev/f/lib/setDefaultModuleLocation
  # but the helper function does not set `key` which breaks deduplication
  key = toString modulePath;

  _file = modulePath;
  imports = [ (if argUsed then f staticArgs else f) ];
}
```

The foot gun I shot myself with was that, the module system keeps the first
module with a given key and never reads the rest:

```console
nix-repl> decl = { lib, ... }: { options.a = lib.mkOption { type = lib.types.anything; }; }
nix-repl> :p (lib.evalModules { modules = [ decl { key = "b"; a = "smth"; } { key = "c"; a = "aaaa"; } ]; }).config
error:
       ...
       error: The option `a' has conflicting definition values:
       - In `<unknown-file>': "aaaa"
       - In `<unknown-file>': "smth"
       Use `lib.mkForce value` or `lib.mkDefault value` to change the priority on any of these definitions.
nix-repl> :p (lib.evalModules { modules = [ decl { key = "b"; a = "smth"; } { key = "b"; a = "aaaa"; } ]; }).config
{ a = "smth"; }
```

This is probably why `lib.modules.importApply` leaves `key` unset on purpose? If
one file applied with different arguments they will be two distinct different
modules, and keying both by path would silently drop one of them. In my config
however every file goes through `modulesFor` with the same
`{ inherit inputs lib; }`, so in my specific use case the path is enough. If you
apply one file with different arguments, DO NOT COPY THIS!

## Bonus: `_module.args.*`?

The other way to give modules an argument is `_module.args`, which is a normal
option. It works fine for anything in a module body:

```console
nix-repl> use = { inputs, lib, ... }: { options.v = lib.mkOption { default = inputs.x; }; }
nix-repl> :p (lib.evalModules { modules = [ use { _module.args.inputs.x = 1; } ]; }).config
{ v = 1; }
```

But this might cause issue in some cases as well. Reading an option needs
`config`, and `config` needs every module's `imports` first, which means pulling
a module out of `inputs` with it will cause infinite recursion.

```console
nix-repl> imp = { inputs, ... }: { imports = [ inputs.dep ]; }
nix-repl> :p (lib.evalModules { modules = [ imp { _module.args.inputs.dep = { }; } ]; }).config
error:
       ...
       ... if you get an infinite recursion here, you probably reference `config` in `imports`. If you are trying to achieve a conditional import behavior dependent on `config`, consider importing unconditionally, and using `mkEnableOption` and `mkIf` to control its effect.
       (stack trace truncated; use '--show-trace' to show the full, detailed trace)
       error: infinite recursion encountered
nix-repl> :p (lib.evalModules { modules = [ imp ]; specialArgs.inputs.dep = { }; }).config
{ }
```

Do note that shared module that sets `_module.args.inputs` for itself collides
with every other module doing the same, even with an identical value, since the
option type is `lazyAttrsOf raw`:

```console
nix-repl> :p (lib.evalModules { modules = [ use { _module.args.inputs.x = 1; } { _module.args.inputs.x = 1; } ]; }).config
error:
       ...
       error: The option `_module.args.inputs' is defined multiple times while it's expected to be unique.
```

Even though `lib.mkForce` and friends on one of them will make the error go away
but by forcefully overriding `inputs` for every module... bruh...
