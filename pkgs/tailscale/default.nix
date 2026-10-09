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
  goVersion = "1.27.2";
  goRev = "509d1573c1cafe9b210180e4ce87f44a409edbba";
  goHash = "sha256-nOaK6f86dZ8zdGktbLNgD7WKH1hm/+QOBpjPdmBQQ5s=";

  tsVersion = "1.105.36";
  tsRev = "b9262195b1fb91c4c8c19624dd34839aa62cf16e";
  tsHash = "sha256-1YWBWaEjK88QBklrxnrd1QXhK1k/rQSYhWPG/WbXoSE=";

  vendorHash = "sha256-PBb0Yl9h7q21nNUl77VjkpVXs+P+9Aq9PcKeO/2757k=";
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
