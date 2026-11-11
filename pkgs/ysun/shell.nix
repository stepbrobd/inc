{ pkgs ? import <nixpkgs> { } }:

let
  preview = pkgs.writeShellScriptBin "preview" ''
    set -euo pipefail
    cd "$(${pkgs.lib.getExe pkgs.git} rev-parse --show-toplevel)/pkgs/ysun"
    exec ${pkgs.lib.getExe pkgs.systemfd} --no-pid --quiet \
      --socket 'http::[::1]:0' -- \
      ${pkgs.lib.getExe pkgs.watchexec} --restart --shell=none \
        --watch src \
        --watch generator \
        --watch build.rs \
        --watch Cargo.toml \
        --watch Cargo.lock \
        -- cargo run -vv
  '';
in
pkgs.mkShell {
  packages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt

    nixpkgs-fmt
    tailwindcss_4
    watchexec
    preview
  ];

  env.BUN_JSC_useJIT = "0";
}
