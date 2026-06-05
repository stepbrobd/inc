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
  version = "1.101.14";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "26864f130233804e2f7c80d3bdf00f8db0942f29";
    hash = "sha256-0NfUF4b3g9qNnPCGyFblVWCH4ypRQ63JGnJsfOeDyxM=";
  };

  vendorHash = "sha256-DUWC+1lbebDwAnhsaGOde3mmD3wHEtMdIyYOMhwxpBU=";
}
