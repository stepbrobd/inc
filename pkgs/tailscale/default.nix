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

  tsVersion = "1.105.74";
  tsRev = "e3c3ef18a51a2d70c902c28f465939888464fb86";
  tsHash = "sha256-bt92wmYSMIRprzZ/3+m31+RPz3L1eec1d2YEqEUBeMk=";

  vendorHash = "sha256-jrznfL26qyAGix9DVkmh0sLU2VvqeTNMdi6mPu9RlxM=";

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
