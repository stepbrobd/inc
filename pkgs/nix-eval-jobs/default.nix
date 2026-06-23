{ pkgsPrev, fetchFromGitHub }:

pkgsPrev.nix-eval-jobs.overrideAttrs (final: prev: {
  version = "2.34.3";

  src = fetchFromGitHub {
    owner = "nixos";
    repo = "nix-eval-jobs";
    tag = "v${final.version}";
    hash = "sha256-YaVQAgBxWbUBFHXLBLzdUyVvuA/DDw80SEnn9iq0Veo=";
  };

  passthru = (prev.passthru or { }) // { autobump = true; };
})
