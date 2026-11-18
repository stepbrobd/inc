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
  goRev = "1635316a95598e9fe1bff7267604daa94aa1c8ec";
  goHash = "sha256-Up4oMG6TVLQkV9inAYF3uYbxu+bMHeU7q9BLcXIllow=";

  tsVersion = "1.105.317";
  tsRev = "075e6403b2cac7ea5357bb14e76e5cdb084ec3ff";
  tsHash = "sha256-3UCoOrZE4yxH8wdkZpKWzBAfQv0/CY1gJ9t+YWhtMis=";

  vendorHash = "sha256-2FUoQbRKmhAbpWH356v/TpgjT9KrcZekMO5E1HbLtMA=";

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
