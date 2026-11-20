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
  goVersion = "1.27.4";
  goRev = "ee691292343f9e120054d09de48b27f42af2af6c";
  goHash = "sha256-Qmy06FkeFkjqCo1FLSD9dO7hTvdo/gC2VACJniuiQBU=";

  tsVersion = "1.105.350";
  tsRev = "2e8f381c2e1872b8b59e4b46cbd84786f3ecc689";
  tsHash = "sha256-mI6Xdno+xKNG0ajlemXhnmP57igBhCfUC2cBGDK4Cmc=";

  vendorHash = "sha256-BqLElx5MlGtEXEkh+2PTo3A38vQjHsQWjHLrXK1K7Zg=";

  builderArg = lib.findSingle
    (n: lib.hasPrefix "buildGo" n && lib.hasSuffix "Module" n)
    (throw "tailscale: no buildGo*Module argument in nixpkgs package")
    (throw "tailscale: multiple buildGo*Module arguments in nixpkgs package")
    (lib.attrNames (lib.functionArgs pkgsPrev.tailscale.override));
in

(pkgsPrev.tailscale.override {
  ${builderArg} = pkgsPrev.buildGoModule.override {
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
  patches = [ ];

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
