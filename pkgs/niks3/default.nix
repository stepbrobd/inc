{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-zYGAd2N3qGavAlT4MggSME7r04kAVn19N7Nh0L0DK5k=";
})
