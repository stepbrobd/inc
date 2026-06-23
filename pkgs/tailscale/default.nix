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
  version = "1.101.93";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "988b0905bb1eda70963514dac0747f4088c1ecb4";
    hash = "sha256-hMmAo4vI5YncZkXkIcHl//gdr9F0pJEzdcneNEDX1Ko=";
  };

  vendorHash = "sha256-w6MF0pKV6zfeVorfrxMm2AXR0uDgw5sG3zl5Ugm6SCU=";
}
