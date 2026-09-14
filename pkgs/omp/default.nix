{ inputs, lib, stdenv }:

inputs.llm.packages.${stdenv.hostPlatform.system}.omp.overrideAttrs (
  { doInstallCheck = false; }
    //
  lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    __darwinAllowLocalNetworking = true;
  }
)
