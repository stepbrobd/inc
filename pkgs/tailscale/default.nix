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
  # go run ./cmd/mkversion
  version = "1.99.0-pre";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "872d79089ead823cf2e930b007d6aad312e05cd2";
    hash = "sha256-F7xaNiec5WR9DERSJeR+qz3XcIPPcSarzqthfN1yzCQ=";
  };

  vendorHash = "sha256-mbxLXR2TBgiwyVGfLmMR5xWk+0f66mPDas95Wla70Lk=";
}
