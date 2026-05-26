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
  version = "1.99.75";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "2eb45c2457bf5360dd21f058a30b00109436ae79";
    hash = "sha256-TI5GqjrFDB0uJEIH9n5lnPQKqY5UbKY0A2P/WjhSJU4=";
  };

  vendorHash = "sha256-HCYBBM2rp4wuwS6x4fvbpJ2R9WHoT5tC1t7d6jtj/n8=";
}
