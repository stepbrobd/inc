{ pkgsPrev, fetchFromGitHub }:

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev.go_1_26.overrideAttrs (final: prev: {
      version = "1.26.2";

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = "dfe2a5fd8ee2e68b08ce5ff259269f50ecadf2f4";
        hash = "sha256-pCvFNTFuvhSBb5O+PPuilaowP4tXcCOP1NgYUDJTcJU=";
      };

      postPatch = (prev.postPatch or "") + ''
        substituteInPlace src/runtime/debug/mod.go \
          --replace-fail "TAILSCALE_GIT_REV_TO_BE_REPLACED_AT_BUILD_TIME" "${final.src.rev}"
      '';
    });
  };
}).overrideAttrs {
  version = "1.96.5";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "f3b2f9b0ef09ed20119f5b89a9652b14ccd94122";
    hash = "sha256-C9H8khbEOY6BS2dln7Nn2J/M3kr0mIwpu+SDsOg/nLE=";
  };

  vendorHash = "sha256-5uzkG6NQh0znjgE6yV5b01y8bUlTvLqXyAoWbMRQNEY=";
}
