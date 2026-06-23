{ pkgsPrev, fetchFromGitHub }:

pkgsPrev.nix-eval-jobs.overrideAttrs {
  version = "2.34.1-unstable-2026-06-09";

  src = fetchFromGitHub {
    owner = "nixos";
    repo = "nix-eval-jobs";
    rev = "d9ec9db619ef122bab8c78ceadee787e997ba277";
    hash = "sha256-DN2BqRVm5GdgzYsnV1D/+7tfjVngu5RbjzzFJqf6hdU=";
  };
}
