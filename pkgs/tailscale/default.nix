{ pkgsPrev, fetchFromGitHub }:

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev.go_1_26.overrideAttrs (final: prev: {
      version = "1.26.1";

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = "179b46cade24e44f53b53a3cbcc7b7eb78469c31";
        hash = "sha256-VH+AgB1qjopwiB4w2SHrJm61O6yAl5ZaCGaDYnzb03o=";
      };

      postPatch = (prev.postPatch or "") + ''
        substituteInPlace src/runtime/debug/mod.go \
          --replace-fail "TAILSCALE_GIT_REV_TO_BE_REPLACED_AT_BUILD_TIME" "${final.src.rev}"
      '';
    });
  };
}).overrideAttrs {
  version = "1.97.133+18781";

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "tailscale";
    rev = "1341f79c6ca79581752214d2466f1c4bb591a16a";
    hash = "sha256-M3ZLPSNg0X6aiYHWZR+gZhOZhRxOmvLZ5pU22+7G734=";
  };

  vendorHash = "sha256-39axT5Q0+fNTcMgZCMLMNfJEJN46wMaaKDgfI+Uj+Ps=";
}
