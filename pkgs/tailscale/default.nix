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
  goRev = "7b6f1558e73b1b5be03374b65687836ff9322e90";
  goHash = "sha256-yyYfWG5c1bxKLfkmP0sWYRYhscwMm1d/pSWhw7hUsi4=";

  tsVersion = "1.103.229";
  tsRev = "e2ed432399c9b0fda7aa14e9eb27784d2d893c55";
  tsHash = "sha256-C9yB3eXQ5Q+/mDUV6fsM99y8hPizXSjzYvMla/6mVqg=";

  vendorHash = "sha256-lN0JafHPgjNSrYYXdlnLtQoHVrfR3a6EqwE7AsFq1+A=";
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
