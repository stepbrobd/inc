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
  version = "1.99.128";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "7f3bbc98657182da74fa497d63efc5bbd68b0a0f";
    hash = "sha256-zgzk4YA13dKrqU4gsG7u5mBSGerC7zB8aFYG0at08Iw=";
  };

  vendorHash = "sha256-8Uv/4rY5pNjhd1ngMQG8Pv18j6YXQveVTYcktv5GjeU=";
}
