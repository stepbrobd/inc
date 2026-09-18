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

let
  goVersion = "1.27.1";
  goRev = "32e8826b089fee8cb0c5c4822b9794ca5004f23a";
  goHash = "sha256-6Bv2BX2mMiWO8gVkqHOq4MmRD1IvWrogYgZ5xuTODQI=";

  tsVersion = "1.103.289";
  tsRev = "28836381da54dad94a72d109d4896e5fa9e88de9";
  tsHash = "sha256-60Gk7CKC/5g0O5KlblqAAfuEMKeUcZ4nkylpeHmJmG8=";

  vendorHash = "sha256-R1DM4hxn3ZM4DzpNlc3CpjhkPyVSLYyPyTsMkLI7Ljc=";
in

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev."go_1_${lib.versions.minor goVersion}".overrideAttrs (prev: {
      version = goVersion;

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = goRev;
        hash = goHash;
      };

      postPatch = (prev.postPatch or "") + ''
        substituteInPlace src/runtime/debug/mod.go \
          --replace-fail "TAILSCALE_GIT_REV_TO_BE_REPLACED_AT_BUILD_TIME" "${goRev}"
      '';
    });
  };
}).overrideAttrs (prev: {
  version = tsVersion;

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = tsRev;
    hash = tsHash;
  };

  inherit vendorHash;

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
