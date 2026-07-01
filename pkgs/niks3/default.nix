{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-c1rVbKR3MkQmFNtEFNGoNLb5o8gNHYwIx+acF2/Ag3c=";
})
