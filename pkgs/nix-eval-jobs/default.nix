{ pkgsPrev, fetchFromGitHub }:

pkgsPrev.nix-eval-jobs.overrideAttrs (final: prev: {
  version = "2.34.2";

  src = fetchFromGitHub {
    owner = "nixos";
    repo = "nix-eval-jobs";
    tag = "v${final.version}";
    hash = "sha256-BtL2NmpXyrVRc3ffxLiIj193T5dCX+0A8Fot+uMM6uI=";
  };

  passthru = (prev.passthru or { }) // { autobump = true; };
})
