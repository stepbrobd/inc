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
  goVersion = "1.27.3";
  goRev = "7ef7b403648ac3a9481a6e88e8b894eff50b0167";
  goHash = "sha256-sdlgTLTkdhTvGCeQTwAsR+Do8rNwBzBUp5QPc09BPgI=";

  tsVersion = "1.105.211";
  tsRev = "b31eb1c9bc582b9251d515ef634cfc99e1fc44e4";
  tsHash = "sha256-DmlIKajYfNyB3+jtY7Ti11ZKHPk6SJTroQafApBZPAU=";

  vendorHash = "sha256-tggEwThh7HDLv6kDuLF+n35wejmsJjduve4zASIneV4=";

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
