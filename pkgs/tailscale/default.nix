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
  goRev = "24ee2fd0610e6c505ee4ec061a81215afe119d1f";
  goHash = "sha256-qxNiwlI/KJpwx7VZQU9C5puJGMUtN5vBXm3ApNYIolI=";

  tsVersion = "1.105.8";
  tsRev = "67f8c81e610d9f469baf648dcea24a9589b17fb6";
  tsHash = "sha256-D6MEEbBV1J+vjbfWGk8bEagVX6SIwqf6MmNW8tz7NL0=";

  vendorHash = "sha256-f9abuyk1qvVr6MPpfmHay6p/U/+8flm1SBmHGjZa1aU=";
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
