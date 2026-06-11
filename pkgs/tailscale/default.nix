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
  version = "1.101.46";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "317201375f92933d43bba86ee8d3590f5e54ab8d";
    hash = "sha256-zEHo2Fd4XIPuBGoxjTunvzCyYyXd8NoQL+ycfvz5VTM=";
  };

  vendorHash = "sha256-M8mPCmO8tp4Kdr1HiuuR+oBYhAeIEENH2tZGaWJa7IY=";
}
