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
  version = "1.99.42";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "4eb977413a1e7453b7c61ccbf39dd067cb5239e7";
    hash = "sha256-S9j8I5qxmOZBu+tABQ04h10A0660ZVC1YxKw3qLy7Bw=";
  };

  vendorHash = "sha256-Xwm+ZLNqd2k7c2GFQJ2Pf/xuFLMcXhYl5I/YVgS9V4U=";
}
