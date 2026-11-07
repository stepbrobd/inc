{ inputs, lib, stdenv, oniguruma, zstd }:

inputs.llm.packages.${stdenv.hostPlatform.system}.omp.overrideAttrs (prev: {
  # TODO: FIXME: drop with the oniguruma and zstd args once llm-agents' omp has both in buildInputs
  # nixpkgs#537108 makes zstd-sys and onig_sys link the system libraries
  buildInputs = prev.buildInputs or [ ] ++ [ oniguruma zstd ];
} // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
  __darwinAllowLocalNetworking = true;
})
