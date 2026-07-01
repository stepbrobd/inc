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
  version = "1.101.140";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "85d8644215637b371c3965e9f38b5d5969b2846c";
    hash = "sha256-TEiuExVoVhoraWXsKFe6HIRVUamgPrAkihx1UjLhDtw=";
  };

  vendorHash = "sha256-jHFZE8TvqiLd2U4CloE3HzVO9Jq6sDNNTsqDNx7bhHM=";

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
