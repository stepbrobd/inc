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
  version = "1.99.18";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "2f45a6a9d8e180373414d42246914a2fb0af0a0c";
    hash = "sha256-o6AAK9p4RTbJEDT+WdHYO50hW7IoM2iPlXP3ysvzfBQ=";
  };

  vendorHash = "sha256-mbxLXR2TBgiwyVGfLmMR5xWk+0f66mPDas95Wla70Lk=";
}
