# TODO: drop this after https://github.com/nixos/nixpkgs/pull/536355

{ pkgsPrev }:

pkgsPrev.ntpd-rs.overrideAttrs { doCheck = false; }
