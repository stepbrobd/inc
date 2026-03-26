{ pkgsPrev, fetchFromGitHub }:

(pkgsPrev.tailscale.override {
  buildGoModule = pkgsPrev.buildGoModule.override {
    go = pkgsPrev.go_1_26.overrideAttrs {
      version = "1.26.1";

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "go";
        rev = "f4de14a515221e27c0d79446b423849a6546e3a6";
        hash = "sha256-qmX68/Ml/jvf+sD9qykdx9QhSbkYaF8xJMFtd3iLHI8=";
      };
    };
  };
}).overrideAttrs {
  version = "1.97.94+18781";

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "tailscale";
    rev = "caf67b2df9d7f2aab2b2fee3be2a77cada79e736";
    hash = "sha256-bEMBsjPT7vqQNO//Nlp/rAomoZsD0uHRnluEqQPbFOs=";
  };

  vendorHash = "sha256-39axT5Q0+fNTcMgZCMLMNfJEJN46wMaaKDgfI+Uj+Ps=";
}
