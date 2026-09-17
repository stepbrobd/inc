{ inputs, lib, stdenv }:

inputs.llm.packages.${stdenv.hostPlatform.system}.omp.overrideAttrs (
  lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    __darwinAllowLocalNetworking = true;
  }
)
