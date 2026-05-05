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
  version = "1.97.338";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "aa21b0c0082040892064a4d4af0aabdc78dde653";
    hash = "sha256-7HC9eGoFQTgTEijbNchlTzeZhQbrRvbfu8OjLml04iM=";
  };

  vendorHash = "sha256-mbxLXR2TBgiwyVGfLmMR5xWk+0f66mPDas95Wla70Lk=";
}
