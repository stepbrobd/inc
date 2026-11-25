{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    cargo
    cargo-nextest
    clippy
    rust-analyzer
    rustc
    rustfmt

    nixpkgs-fmt
  ];
}
