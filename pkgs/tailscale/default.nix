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
  goRev = "c46f95b7f7c2ebe520044ef131d6ce730d7e4a82";
  goHash = "sha256-+cTlDLusJthxTayVx6yGoqZHRN4ylvs/9Qpy4P2dlDI=";

  tsVersion = "1.103.217";
  tsRev = "7b0d5155ccd2058cce1d402af5decc3265bf2752";
  tsHash = "sha256-p6Y3cZdmb4m2X8ogEHWYt91fTW+3zcYGzEeBw1ZPhUk=";

  vendorHash = "sha256-ymYDwGo15grikyBCgjX1XwxjTjUocx61tr8TIk+E8uQ=";
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
