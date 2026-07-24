{ lib
, pkgsPrev
, fetchFromGitHub
, writeShellApplication
, nix-prefetch-github
, coreutils
, git
, gnused
, jq
}:

pkgsPrev.tailscale.overrideAttrs (prev: {
  version = "1.103.3";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "f6fa29463537e027813fb99680f09b0119a9b8ff";
    hash = "sha256-zUcKEJmsi6qWUdiuqPMBhdQ6X46ZdODCl8g5AKuh2/4=";
  };

  vendorHash = "sha256-5ClQ5fSyEHUlhPtZI0ir8ddQRXSnqOG5VIJ3KjWtXmw=";

  passthru = (prev.passthru or { }) // {
    autobump = true;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "tailscale-updater";
        text = lib.readFile ./update.sh;
        runtimeInputs = [
          coreutils
          git
          gnused
          jq
          nix-prefetch-github
        ];
      }))
    ];
  };
})
