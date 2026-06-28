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
  version = "1.101.127";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "4bb6f35c1f89df94eb462640abc8aab3c691da11";
    hash = "sha256-n8Tr5gGnWyXI+0ImaxxOklZpJK7SZYjY+5Pm9R6scnc=";
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
