{ lib
, stdenv
, writeShellScriptBin
, cargo
, clippy
, git
, nixpkgs-fmt
, rustc
, rustfmt
, taplo
}:

writeShellScriptBin "formatter" ''
  export PATH="${lib.makeBinPath [
    cargo
    clippy
    nixpkgs-fmt
    rustc
    rustfmt
    stdenv.cc
    taplo
  ]}"

  set -eoux pipefail
  shopt -s globstar

  pushd "$(${lib.getExe git} rev-parse --show-toplevel)/pkgs/aniremind" > /dev/null

  cargo clippy --all-targets --all-features --fix --allow-dirty -- -D warnings
  cargo fmt --all
  nixpkgs-fmt .
  taplo format

  popd
''
