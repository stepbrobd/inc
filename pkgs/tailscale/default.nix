{ pkgsPrev, fetchFromGitHub }:

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev.go_1_26.overrideAttrs (final: prev: {
      version = "1.26.4";

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = "c803676bcc7f2b195b167a53d49d728045cd9b36";
        hash = "sha256-cY5yryX+p/xtoTv+WZEKFagiIl0OREHnJY1Bk5VpVVc=";
      };

      postPatch = (prev.postPatch or "") + ''
        substituteInPlace src/runtime/debug/mod.go \
          --replace-fail "TAILSCALE_GIT_REV_TO_BE_REPLACED_AT_BUILD_TIME" "${final.src.rev}"
      '';
    });
  };
}).overrideAttrs {
  # go run ./cmd/mkversion
  version = "1.101.19";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "83c8440834313e4e779aec9acf3b18891502d0a8";
    hash = "sha256-hByubDlOi9H8hA9XhSObCfYQyXfPtOeCyLkg4KQzTio=";
  };

  vendorHash = "sha256-DUWC+1lbebDwAnhsaGOde3mmD3wHEtMdIyYOMhwxpBU=";
}
