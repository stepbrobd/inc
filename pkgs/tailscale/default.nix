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
  goRev = "186053ab2af2ef8fc43f3c1d1150216e89d4aff0";
  goHash = "sha256-JcOxcYFhNRg6fiQhe5GkPHQxLI0ypKClCShZcBY1920=";

  tsVersion = "1.105.66";
  tsRev = "e9d5cdc3231edd3f93254c16f505fd86344a9faf";
  tsHash = "sha256-aw82+7HtzKDTF+6vtw5AAlW+IJWiVAHhdmFrSuaqYwM=";

  vendorHash = "sha256-IdLueIhe79sg12fQ7fHAEtLmSfhLp+bwXINcH38bhjw=";

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
