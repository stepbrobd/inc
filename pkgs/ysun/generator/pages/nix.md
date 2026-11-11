---
title: My outdated Nix way
description: Manage your system configurations + packages + ... my Nix way
created: 2023-12-08
updated: 2026-09-14
hidden: true
---

> Note that this page is no longer maintained and has been marked as hidden. See
> [github:stepbrobd/inc](https://github.com/stepbrobd/inc) for details.

Outdated and I'm too lazy to change anything here, just read my code.

This is a guide to my personal
[dotfiles repo](https://github.com/stepbrobd/dotfiles) (for NixOS and Darwin
systems), use it as a reference to create your own.

## Installation

I suggest anyone that wants to try out Nix not to use the official installer,
but to use the
[Nix Installer](https://github.com/determinatesystems/nix-installer) by
Determinate Systems. It installs Nix, while providing a way to easily remove it
from your system.

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
```

## Flakes?

If you are following online guides, a lot of those will probably tell you to run
some commands start with `nix-env` or `nix-channel`, don't use it! Those `nix-`
commands are [channel based](https://nixos.wiki/wiki/Nix_channels), while
"reproducible", but hard to maintain. Instead, use
[Nix Flakes](https://nixos.wiki/wiki/Flakes), think of it as a way to pin
channels to a specific commit, so you can get the same result every time if the
same flake inputs are given.

While Nix Flakes are still marked as "experimental", but
[it does not mean it's unstable](https://determinate.systems/posts/experimental-does-not-mean-unstable).
Members of the Nix community are already using flakes at scale, I don't really
see any way of flakes being removed from Nix.

If you installed Nix using the DetSys Nix Installer, you should already have
flakes enabled. If not, prefix all `nix` commands with
`nix --extra-experimental-features "nix-command flakes"`. If you see something
like
`echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf` in
a guide, don't do it either. Instead, in your flake configurations, enable
experimental features like this (in the module format):

```nix
{
    nix.settings.experimental-features = [
        "flakes"
        "nix-command"
    ];
}
```

Read more about flakes:

- [standard schemas](https://arc.net/l/quote/agerqwyq)
- [extensible schemas](https://determinate.systems/posts/flake-schemas)

## Don't want to use Flakes?

If you don't want to use flakes, there are still ways to pin your dependencies
to a specific commit (the use of channels is not recommended). You can use
[`niv`](https://github.com/nmattia/niv) or
[`npins`](https://github.com/andir/npins) to pin your dependencies.

While `niv` and `npin` are good tools, IMO they are not as good as flakes. You
can achieve similar results with `niv` and `npin`, but you'll have to install
more tools and (potentially) write more code.

Similar effects can also be achieved with
[`flake-compat`](https://github.com/edolstra/flake-compat), but you are still
using flakes, just in a different way.

## Basics

Update (2024-02-01):

Before diving into system configurations, you should understand the following
concepts:

- derivations and closures
- nix store
- using nix as a package manager
- development shell

I prepared a short slide with examples to help you understand these concepts,
you can find it [here](https://github.com/stepbrobd/nixology) and more resources
at the end of this guide.

## Modules

In the example above, `flakes` and `nix-command` are enabled in the format of a
module. Modules can be imported into system configurations, and they are usually
considered as the most basic building blocks of nix-based configurations. They
can be attrsets, or a function that returns an attrset.

Generally, modules are imported directly from flake outputs inside a system
configuration:

```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        nix-darwin = {
            url = "github:lnl7/nix-darwin";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, nix-darwin } @ inputs:
    let
        inherit (self) outputs;
        lib = nixpkgs.lib // nix-darwin.lib;
    in
    {
        nixosConfigurations."nixos-machine-name" = lib.nixosSystem {
            specialArgs = { inherit inputs outputs; };
            modules = [
                ... # put modules here
            ];
        };
        darwinConfigurations."darwin-machine-name" = lib.darwinSystem {
            specialArgs = { inherit inputs outputs; };
            modules = [
                ... # put modules here
            ];
        };
    };
}
```

The `specialArgs` is used to pass arguments to modules, we added `inputs` and
`outputs` to it so we can use them in modules like this:

```nix
{ inputs, outputs, ... }:

{
    ... # inputs and outputs are available here
    # example: inputs.nixpkgs or inputs.nix-darwin
    # example: outputs.nixosConfigurations."nixos-machine-name"
    # be very careful when using outputs, it can cause infinite recursion
}
```

[Standard arguments](https://arc.net/l/quote/fkjnloyb) like `config`, `pkgs`,
`modulePath`, ... are passed to modules automatically.

## Getting Started on Configurations

Depending on whether you have a NixOS or Darwin system (or both), you should
decide on these couple of things:

- How many host machines do you have? Is it really worth it spending time on
  Nix?
- NixOS or Darwin? Or both (you've got to think it through if you want to have
  both, it'll be quite messy)?
- Do you want to use
  [home-manager](https://github.com/nix-community/home-manager) (considering
  `nixpkgs` and `nix-darwin` both have limited configuration options, I
  personally strongly recommend using home-manager)?
- Standalone home-manager or integrate it directly into your system
  configuration (standalone meaning you'll need to run `home-manager switch`
  instead of it automatically kicks in when rebuilding the system with
  `{nixos,darwin}-switch`)?

Let's continue with the assumption that you have multiple NixOS and Darwin
machines, and you want to use home-manager integrated into your system
configuration. The first step would be adding flake inputs:

```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        nix-darwin = {
            url = "github:lnl7/nix-darwin";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, nix-darwin, home-manager, ... } @ inputs:
    let
        inherit (self) outputs;
        lib = nixpkgs.lib // nix-darwin.lib // home-manager.lib; # merge all libs together so we don't need to use them separately
    in
    {
        nixosConfigurations."nixos-machine-name" = lib.nixosSystem {
            specialArgs = { inherit inputs outputs; };
            modules = [
                ... # put modules here
            ];
        };
        darwinConfigurations."darwin-machine-name" = lib.darwinSystem {
            specialArgs = { inherit inputs outputs; };
            modules = [
                ... # put modules here
            ];
        };
    };
}
```

This is rather cumbersome, let's extract the common section out:

```nix
{
    inputs = { ... }; # same as above

    outputs = { self, nixpkgs, nix-darwin, home-manager, ... } @ inputs:
    let
        inherit (self) outputs;
        lib = nixpkgs.lib // nix-darwin.lib // home-manager.lib; # merge all libs together so we don't need to use them separately
        mkSystem = { type, platform, config, username, stateVersion, hmstateVersion, extraModules, extraHMModules }: lib."${type}System" {
            specialArgs = { inherit inputs outputs; };
            modules = [
                config # path to system config, hardware configs are usually imported inside the config
                { nixpkgs.hostPlatform = lib.mkDefault platform; } # set host platform
                { system.stateVersion = stateVersion; }                                  # state version
                { home-manager.users."${username}".home.stateVersion = hmstateVersion; } # home-manager state version

                # system user
                (../. + "/users/${username}") # or change it based on your directory structure

                # integrated home-manager
                home-manager."${type}Modules".home-manager
                {
                  home-manager.extraSpecialArgs = { inherit inputs outputs; };
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users."${username}" = {
                    imports = [
                      (../. + "/users/${username}/home.nix") # or change it based on your directory structure
                    ] ++ extraHMModules;
                  };
                }
            ] ++ extraModules;
        };
    in
    {
        # rec means recursive attrset, attrs inside recursive attrset can refer to other attrs inside the scope
        nixosConfigurations."nixos-machine-name" = mkSystem rec { # we are using rec here since home-manager state version is the same as nixos state version
            type = "nixos";
            platform = "x86_64-linux"; # or "aarch64-linux"
            config = ./path/to/nixos/configuration.nix;
            username = "your-username";
            stateVersion = "24.05";         # string type
            hmstateVersion = stateVersion;  # string type
            extraModules = [
                # extra nixos modules
            ];
            extraHMModules = [
                # extra home-manager modules
            ];
        };
        # we don't need to use rec here since we are not referring to other attrs
        darwinConfigurations."darwin-machine-name" = mkSystem {
            type = "darwin";
            platform = "x86_64-darwin"; # or "aarch64-darwin"
            config = ./path/to/darwin/configuration.nix;
            username = "your-username";
            stateVersion = 4;              # integer type
            hmstateVersion = "24.05";      # string type
            extraModules = [
                # extra darwin modules
            ];
            extraHMModules = [
                # extra home-manager modules
            ];
        };
    };
}
```

`mkSystem` is a function that returns a system config, it assumes you have the
following directory structure:

```txt
- flake.nix
- flake.lock
- some-other-directory-that-stores-your-system-config
  - ...
- some-other-directory-that-stores-your-modules
  - ...
- users
  - your-username
    - home.nix    # home-manager module
    - default.nix # nixos/darwin module
```

You can change the directory structure, but you'll need to change the paths in
`mkSystem` accordingly. Note that `users/${username}/default.nix` is a
nixos/darwin module, it's content must match the definitions in
[nixpkgs](https://mynixos.com/nixpkgs/option/users.users) or
[nix-darwin](https://mynixos.com/nix-darwin/option/users.users).
`users/${username}/home.nix` is a home-manager module, it's content must match
the definitions in
[home-manager](https://mynixos.com/home-manager/options/home). Similarly, the
modules in `extraModules` must be from
[nixpkgs](https://mynixos.com/nixpkgs/options) or
[nix-darwin](https://mynixos.com/nix-darwin/options), and the modules in
`extraHMModules` must be from
[home-manager](https://mynixos.com/home-manager/options). Putting the `mkSystem`
function in a separate file is also a good idea, check out
[Haumea](https://github.com/nix-community/haumea) to easily manage your custom
libraries.

## Conflicts? System-Dependent Configs?

Some options might only be available in nixpkgs options but not in nix-darwin
options, or vice versa. To address this,
[`lib.optionalAttrs`](https://ryantm.github.io/nixpkgs/functions/library/attrsets/#function-library-lib.attrsets.optionalAttrs)
can be very useful:

```nix
{ config
, lib
, pkgs
, ...
}:

{
  programs.zsh.enable = true;

  users.users."your-username" = {
    shell = pkgs.zsh;

    description = "Your Username";
    home =
      if pkgs.stdenv.isLinux
      then lib.mkDefault "/home/your-username"
      else if pkgs.stdenv.isDarwin
      then lib.mkDefault "/Users/your-username"
      else abort "Unsupported OS";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 ...";
      "ssh-ed25519 ...";
    ];
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" "audio" "video" ];
    hashedPassword = "...";
  };
}
```

In the example above, `users.users.<username>.isNormalUser` is only available in
nixpkgs (for NixOS systems, not Darwin), so we use
`lib.optionalAttrs pkgs.stdenv.isLinux` to make it only available on Linux
systems or nix-darwin will throw an error.

Also, if you only want some packages to be installed on a specific system,
`lib.optionals` can make attributes appear or disappear based on conditions:

```nix
{ config
, lib
, pkgs
, ...
}:

{
  # available on all systems
  home.packages = with pkgs; [
    nix-output-monitor
    # ...
  ]
  # linux only and when hyprland is enabled
  ++ (lib.optionals (pkgs.stdenv.isLinux && config.wayland.windowManager.hyprland.enable) [
    cider
    # ...
  ])
  # darwin only
  ++ (lib.optionals pkgs.stdenv.isDarwin [
    cocoapods
    # ...
  ]);
}
```

## Resources

Nix's documentation is bad, my best advise is get used to reading the source
code, and messing around with it using `nix repl`. Instead of complaining about
the documentation, use online resources like
[official discourse](https://discourse.nixos.org) and
[github code search](https://github.com/features/code-search) (query with
`lang:Nix`).

- [zero to nix](https://zero-to-nix.com)
- [nix wiki](https://nixos.wiki): usually outdated, but still useful
- [nix pills](https://nixos.org/guides/nix-pills)
- [nix manual](https://nixos.org/manual/nix/unstable)
- [nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable)
- [mynixos](https://mynixos.com): a very nice tool to search for options
- [direnv](https://direnv.net): a tool to automatically load/unload environment
  variables
- ... the rest is up to your imagination
