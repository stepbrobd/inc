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
  version = "1.97.231";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "c2da563fef77a9242a70321722ef3d4856cc566d";
    hash = "sha256-HUcjrtOJOBAlKhxtC73LYp0PC05luVc02kWGCzOZ+hE=";
  };

  vendorHash = "sha256-rRjz9+V33DVblvNtQGEllK0NF82FgVkOtoIT47e5Nd0=";
}
