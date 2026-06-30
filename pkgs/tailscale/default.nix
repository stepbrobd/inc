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
  version = "1.101.132";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "477d5a43df073f3dae17cca7fd86a6487b8bb7d3";
    hash = "sha256-Xgrf0L4zLBv0AgG7pdBLz+8m5j1TYkldob1DuTkN2z4=";
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
