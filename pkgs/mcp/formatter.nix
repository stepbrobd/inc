{ lib
, stdenv
, writeShellScriptBin
, cargo
, clippy
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

  root="$PWD"
  while [[ ! -f "$root/Cargo.toml" ]]; do
    if [[ "$root" == "/" ]]; then
      echo "no Cargo.toml found" >&2
      exit 1
    fi
    root="$(dirname "$root")"
  done

  pushd "$root" > /dev/null

  cargo clippy --all-targets --all-features --fix --allow-dirty -- -D warnings
  cargo fmt --all
  nixpkgs-fmt .
  taplo format

  popd
''
