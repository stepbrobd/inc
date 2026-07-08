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
  version = "1.101.169";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "887005d25566ae97aaec23137d7e84e8f2e01862";
    hash = "sha256-heofUlrrdRCKOh1+1PXN1AxgK0k2l0jv0zkO+BUmaU8=";
  };

  vendorHash = "sha256-sWU4abv9Oz7P21ivL5zgdYNGiJSXamnQR0VmRGKoIrI=";

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
