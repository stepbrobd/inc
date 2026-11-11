{ lib
, stdenv
, writeShellScriptBin
, apple-sdk
, cargo
, clippy
, git
, nixpkgs-fmt
, rustc
, rustfmt
, tailwindcss_4
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
    tailwindcss_4
    taplo
  ]}"
  export BUN_JSC_useJIT=0
  ${lib.optionalString stdenv.buildPlatform.isDarwin ''
    export SDKROOT="${apple-sdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
    export MACOSX_DEPLOYMENT_TARGET="${stdenv.hostPlatform.darwinMinVersion}"
  ''}

  set -eoux pipefail
  shopt -s globstar

  pushd "$(${lib.getExe git} rev-parse --show-toplevel)/pkgs/ysun" > /dev/null

  cargo clippy --all-targets --all-features --fix --allow-dirty -- -D warnings
  cargo fmt --all
  nixpkgs-fmt .
  taplo format

  popd
''
