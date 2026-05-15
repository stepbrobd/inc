{ pkgsPrev, fetchFromGitHub }:

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev.go_1_26.overrideAttrs (final: prev: {
      version = "1.26.3";

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = "e877d973840c91ec9d4bc1921b0845789de359ae";
        hash = "sha256-HeD70CytKL0Ks/VDqMU73bN8fxpWkNc6mNgNr9PEO7k=";
      };

      postPatch = (prev.postPatch or "") + ''
        substituteInPlace src/runtime/debug/mod.go \
          --replace-fail "TAILSCALE_GIT_REV_TO_BE_REPLACED_AT_BUILD_TIME" "${final.src.rev}"
      '';
    });
  };
}).overrideAttrs {
  # go run ./cmd/mkversion
  version = "1.99.48";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "c355618e734c8d585b4d1e8289c1f98db07f6421";
    hash = "sha256-NUIb9HtLUEBRbO0V8LkSh/u+LmlgaWGDHGch85jT958=";
  };

  vendorHash = "sha256-Xwm+ZLNqd2k7c2GFQJ2Pf/xuFLMcXhYl5I/YVgS9V4U=";
}
