{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt

    nixpkgs-fmt
  ];
}
