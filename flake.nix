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
            config.allowUnfree = true;
            overlays = with inputs; [
              self.overlays.default
              colmena.overlays.default
              llm.overlays.default
              ranet.overlays.default
              rust-overlay.overlays.default
              terraform-providers.overlays.default
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
    # TODO: remove after https://github.com/nix-darwin/nix-darwin/pull/1789
    # darwin.url = "github:nix-darwin/nix-darwin";
    # remove after 
    darwin.url = "github:stepbrobd/nix-darwin/bundle";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # g
    generators.url = "github:nix-community/nixos-generators";
    generators.inputs.nixpkgs.follows = "nixpkgs";
    generators.inputs.nixlib.follows = "nixpkgs";
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.url = "github:nix-community/gomod2nix";
    gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
    gomod2nix.inputs.flake-utils.follows = "utils";
    # h
    hardware.url = "github:nixos/nixos-hardware";
    hardware.inputs.nixpkgs.follows = "nixpkgs";
    hm.url = "github:nix-community/home-manager";
    hm.inputs.nixpkgs.follows = "nixpkgs";
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
    miroir.url = "github:stepbrobd/miroir";
    miroir.inputs.nixpkgs.follows = "nixpkgs";
    miroir.inputs.systems.follows = "systems";
    miroir.inputs.parts.follows = "parts";
    miroir.inputs.utils.follows = "utils";
    miroir.inputs.gomod2nix.follows = "gomod2nix";
    # n
    # after v5 release, switch to noctalia-greeter
    # https://github.com/noctalia-dev/noctalia-greeter
    noctalia.url = "github:noctalia-dev/noctalia";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";
    niks3.url = "github:mic92/niks3";
    niks3.inputs.nixpkgs.follows = "nixpkgs";
    niks3.inputs.treefmt-nix.follows = "treefmt";
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
    systems.url = "github:nix-systems/triplet";
    # r
    ranet.url = "github:nickcao/ranet";
    ranet.inputs.nixpkgs.follows = "nixpkgs";
    ranet.inputs.flake-utils.follows = "utils";
    # t
    terraform-providers.url = "github:nix-community/nixpkgs-terraform-providers-bin";
    terraform-providers.inputs.nixpkgs.follows = "nixpkgs";
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

  nixConfig.extra-substituters = [ "https://cache.ysun.co" ];
  nixConfig.extra-trusted-public-keys = [ "cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4=" ];
}
