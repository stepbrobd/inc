{ lib
, pkgsPrev
, fetchFromGitHub
, writeShellApplication
, nix-prefetch-github
, coreutils
, git
, gnused
, go
, jq
}:

pkgsPrev.tailscale.overrideAttrs (prev: {
  # go run ./cmd/mkversion
  version = "1.101.93";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "988b0905bb1eda70963514dac0747f4088c1ecb4";
    hash = "sha256-hMmAo4vI5YncZkXkIcHl//gdr9F0pJEzdcneNEDX1Ko=";
  };

  vendorHash = "sha256-w6MF0pKV6zfeVorfrxMm2AXR0uDgw5sG3zl5Ugm6SCU=";

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
          go
          jq
          nix-prefetch-github
        ];
      }))
    ];
  };
})
