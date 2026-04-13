{
  description = "@stepbrobd: yet another dotfiles repo with nix";

  outputs =
    { self, ... }@inputs:
    inputs.autopilot.lib.mkFlake
      {
        inherit inputs;

        autopilot = {
          lib = {
            path = ./lib;
            extender = inputs.nixpkgs.lib;
            excludes = [ "secrets.yaml" ];
            extensions = with inputs; [
              autopilot.lib
              colmena.lib
              darwin.lib
              hm.lib
              parts.lib
              terranix.lib
              utils.lib
              { std = inputs.std.lib; }
            ];
          };

          nixpkgs = {
            config = {
              allowUnfree = true;
              allowDeprecatedx86_64Darwin = true;
            };
            overlays = with inputs; [
              self.overlays.default
              colmena.overlays.default
              golink.overlays.default
              llm.overlays.default
              mac-style-plymouth.overlays.default
              ranet.overlays.default
              rust-overlay.overlays.default
            ];
            instances = {
              pkgs = inputs.nixpkgs;
            };
          };

          parts.path = ./modules/flake;
        };
      }
      {
        debug = true;
        systems = import inputs.systems;
      };

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # a
    autopilot.url = "github:stepbrobd/autopilot";
    autopilot.inputs.nixpkgs.follows = "nixpkgs";
    autopilot.inputs.parts.follows = "parts";
    autopilot.inputs.systems.follows = "systems";
    # b
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
    blueprint.inputs.systems.follows = "systems";
    bun2nix.url = "github:nix-community/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
    bun2nix.inputs.systems.follows = "systems";
    bun2nix.inputs.flake-parts.follows = "parts";
    bun2nix.inputs.treefmt-nix.follows = "treefmt";
    # c
    colmena.url = "github:stepbrobd/colmena/detached";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    colmena.inputs.stable.follows = "nixpkgs";
    colmena.inputs.flake-compat.follows = "compat";
    colmena.inputs.flake-utils.follows = "utils";
    colmena.inputs.nix-github-actions.follows = "";
    compat.url = "github:edolstra/flake-compat";
    compat.flake = false;
    cornflake.url = "github:jzbor/cornflakes";
    crane.url = "github:ipetkov/crane";
    # d
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # f
    flatpak.url = "github:gmodena/nix-flatpak";
    # g
    garnix.url = "github:garnix-io/garnix-lib/systemd-networkd-experiment";
    garnix.inputs.nixpkgs.follows = "nixpkgs";
    generators.url = "github:nix-community/nixos-generators";
    generators.inputs.nixpkgs.follows = "nixpkgs";
    generators.inputs.nixlib.follows = "nixpkgs";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
    golink.url = "github:tailscale/golink";
    golink.inputs.nixpkgs.follows = "nixpkgs";
    golink.inputs.systems.follows = "systems";
    gomod2nix.url = "github:nix-community/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.inputs.flake-utils.follows = "utils";
    # h
    hardware.url = "github:nixos/nixos-hardware";
    hm.url = "github:nix-community/home-manager";
    hm.inputs.nixpkgs.follows = "nixpkgs";
    # hydra.url = "github:ners/hydra/oidc";
    # hydra.inputs.nixpkgs.follows = "nixpkgs";
    # i
    index.url = "github:nix-community/nix-index-database";
    index.inputs.nixpkgs.follows = "nixpkgs";
    # l
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.crane.follows = "crane";
    lanzaboote.inputs.rust-overlay.follows = "rust-overlay";
    lanzaboote.inputs.pre-commit.follows = "";
    llm.url = "github:numtide/llm-agents.nix";
    llm.inputs.nixpkgs.follows = "nixpkgs";
    llm.inputs.systems.follows = "systems";
    llm.inputs.flake-parts.follows = "parts";
    llm.inputs.blueprint.follows = "blueprint";
    llm.inputs.bun2nix.follows = "bun2nix";
    llm.inputs.treefmt-nix.follows = "treefmt";
    # m
    mac-style-plymouth.url = "github:sergioribera/s4rchiso-plymouth-theme";
    mac-style-plymouth.inputs.nixpkgs.follows = "nixpkgs";
    mac-style-plymouth.inputs.flake-utils.follows = "utils";
    miroir.url = "github:stepbrobd/miroir";
    miroir.inputs.nixpkgs.follows = "nixpkgs";
    miroir.inputs.systems.follows = "systems";
    miroir.inputs.parts.follows = "parts";
    miroir.inputs.utils.follows = "utils";
    miroir.inputs.gomod2nix.follows = "gomod2nix";
    # n
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.inputs.noctalia-qs.follows = "noctalia-qs";
    noctalia-qs.url = "github:noctalia-dev/noctalia-qs";
    noctalia-qs.inputs.nixpkgs.follows = "nixpkgs";
    noctalia-qs.inputs.systems.follows = "systems";
    noctalia-qs.inputs.treefmt-nix.follows = "treefmt";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.inputs.flake-parts.follows = "parts";
    nixvim.inputs.systems.follows = "systems";
    # p
    parts.url = "github:hercules-ci/flake-parts";
    parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    # r
    rfm.url = "github:stepbrobd/rfm";
    rfm.inputs.nixpkgs.follows = "nixpkgs";
    rfm.inputs.parts.follows = "parts";
    rfm.inputs.utils.follows = "utils";
    rfm.inputs.systems.follows = "systems";
    rfm.inputs.gomod2nix.follows = "gomod2nix";
    rpi.url = "github:nvmd/nixos-raspberrypi";
    rpi.inputs.nixpkgs.follows = "nixpkgs";
    rpi.inputs.flake-compat.follows = "compat";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # s
    schemas.url = "github:determinatesystems/flake-schemas";
    sops.url = "github:mic92/sops-nix";
    sops.inputs.nixpkgs.follows = "nixpkgs";
    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";
    std.url = "github:chessai/nix-std";
    sweep.url = "github:jzbor/nix-sweep";
    sweep.inputs.nixpkgs.follows = "nixpkgs";
    sweep.inputs.cf.follows = "cornflake";
    sweep.inputs.crane.follows = "crane";
    systems.url = "github:nix-systems/default";
    # r
    ranet.url = "github:nickcao/ranet";
    ranet.inputs.nixpkgs.follows = "nixpkgs";
    ranet.inputs.flake-utils.follows = "utils";
    # t
    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";
    terranix.inputs.flake-parts.follows = "parts";
    terranix.inputs.systems.follows = "systems";
    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
    # u
    uad2.url = "github:stepbrobd/uad2";
    uad2.inputs.nixpkgs.follows = "nixpkgs";
    uad2.inputs.parts.follows = "parts";
    uad2.inputs.systems.follows = "systems";
    utils.url = "github:numtide/flake-utils";
    utils.inputs.systems.follows = "systems";
    # y
    ysun.url = "github:stepbrobd/ysun";
    ysun.inputs.nixpkgs.follows = "nixpkgs";
    ysun.inputs.parts.follows = "parts";
    ysun.inputs.systems.follows = "systems";
    # z
    zen.url = "github:youwen5/zen-browser-flake";
    zen.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://colmena.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
  };
}
