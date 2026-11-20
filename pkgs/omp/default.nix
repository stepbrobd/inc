{ inputs, lib, stdenv }:

inputs.llm.packages.${stdenv.hostPlatform.system}.omp.overrideAttrs (lib.optionalAttrs stdenv.hostPlatform.isDarwin {
  doInstallCheck = false;
  __darwinAllowLocalNetworking = true;
})
