{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-dxNk5DWBMyahl36RARCu/JfrpQ6RFATKEuDLEhea5RQ=";
})
