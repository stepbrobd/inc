{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-n9G4z6kd/K0k+QpVhwvxbS5cwmR2uakuGN2nWj4dCkI=";
})
