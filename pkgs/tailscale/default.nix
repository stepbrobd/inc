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
  version = "1.101.303";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "66bb4ac61fe96a56959a2e8d77b949473b1b4d60";
    hash = "sha256-G1Vb8JhXuBODIIVCKheu8U+7D2whJ7BaMlunzfS8GHA=";
  };

  vendorHash = "sha256-amKkUPszyhG4N5ZtrB01swBACYq76raSS+SQRneLmwc=";

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
