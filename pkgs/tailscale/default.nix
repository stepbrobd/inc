{ pkgsPrev, fetchFromGitHub }:

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev.go_1_26.overrideAttrs (final: prev: {
      version = "1.26.3";

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = "7104161f96b07474ce312ea116c8b2a1efe1311a";
        hash = "sha256-uskKJHUzzIQ74VuzoQKrlz+6tCY/YKnv+BjJduPwt6Q=";
      };

      postPatch = (prev.postPatch or "") + ''
        substituteInPlace src/runtime/debug/mod.go \
          --replace-fail "TAILSCALE_GIT_REV_TO_BE_REPLACED_AT_BUILD_TIME" "${final.src.rev}"
      '';
    });
  };
}).overrideAttrs {
  # go run ./cmd/mkversion
  version = "1.99.120";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "c234dcc2ef95823f19aaef109ea1e5960a879336";
    hash = "sha256-unXEp27M2Ia4ZaXM2QbMwE/cH2Zk+rz5Lfhqv7inqQs=";
  };

  vendorHash = "sha256-O8fayMGE9gM/2IamN1AP6Mk8GQTEYGtEeF35iebRkVs=";
}
