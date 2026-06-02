{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) elem filterAttrs mapAttrs mapAttrsToList mkForce optional optionals;
in
{
  system.configurationRevision =
    with inputs.self;
    if sourceInfo ? dirtyShortRev
    then sourceInfo.dirtyShortRev
    else sourceInfo.shortRev;

  # enable nextdns and tailscale on all hosts
  services = {
    nextdns = {
      enable = true;
      arguments = [
        "-config"
        "d8664a"
      ];
    };

    tailscale.enable = true;
  };

  nix = {
    package = pkgs.nixVersions.latest;

    optimise.automatic = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };

    channel.enable = lib.mkForce false;

    registry =
      let
        allowed = [ "nixpkgs" ];
      in
      mkForce (
        mapAttrs (_: value: { flake = value; })
          (filterAttrs (name: _: elem name allowed) inputs)
      );

    nixPath = mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      accept-flake-config = true;
      allow-import-from-derivation = true;
      builders-use-substitutes = true;
      fallback = true;
      flake-registry = "";
      keep-build-log = true;
      keep-derivations = true;
      keep-env-derivations = true;
      keep-failed = true;
      keep-going = true;
      keep-outputs = true;
      max-free = lib.mkDefault (3000 * 1024 * 1024);
      min-free = lib.mkDefault (512 * 1024 * 1024);
      narinfo-cache-negative-ttl = 3600;
      narinfo-cache-positive-ttl = 3600;
      use-xdg-base-directories = true;
      warn-dirty = false;

      sandbox = if pkgs.stdenv.isDarwin then "relaxed" else true;
      extra-sandbox-paths = optionals pkgs.stdenv.isDarwin [
        "/System/Library/Frameworks"
        "/System/Library/PrivateFrameworks"
        "/private/tmp"
        "/private/var/tmp"
        "/usr/bin/env"
        "/usr/lib"
      ];

      trusted-users = [ "root" ]
        ++ (optional pkgs.stdenv.isLinux "@wheel")
        ++ (optional pkgs.stdenv.isDarwin "@admin");

      experimental-features = [
        "auto-allocate-uids"
        "ca-derivations"
        "cgroups"
        "flakes"
        "impure-derivations"
        "nix-command"
        "pipe-operators"
      ];

      substituters = lib.mkForce [
        "https://cache.ysun.co?priority=10"
        "https://cache.nixos.org?priority=15"
        "https://cache.garnix.io?priority=20" # remove after july 15
        "https://nix-community.cachix.org?priority=30"
        "https://temp-cache.nix-community.org?priority=30"
        "https://nixpkgs-update.cachix.org?priority=30"
        "https://nixos-raspberrypi.cachix.org?priority=30"
        "https://stepbrobd.cachix.org?priority=40"
        "https://noctalia.cachix.org?priority=40"
      ];

      trusted-public-keys = lib.mkForce [
        "cache.ysun.co-1:WxPYwT5g3kt9XhUhHPpNLZKI9HIOsVVAuqSHpok8Qt4="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" # remove after july 15
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "temp-cache.nix-community.org-1:RSXIfGjilfBsilDvj03/VnL/9qAxacBnb1YQvSdCoDc="
        "nixpkgs-update.cachix.org-1:6y6Z2JdoL3APdu6/+Iy8eZX2ajf09e4EE9SnxSML1W8="
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        "stepbrobd.cachix.org-1:Aa5jdkPVrCOvzaLTC0kVP5PYQ5BtNnLg1tG1Qa/QuE4="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
    file
    inputs.sweep.packages.${pkgs.stdenv.hostPlatform.system}.default
    nix-eval-jobs
  ];

  # pager
  environment.variables.PAGER = "less -FRX";

  # shells
  environment.shells = with pkgs; [ bashInteractive nushell zsh ];
}
