{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-xfpOL8JFfqYz2AncprLAL+9UGglwU1OL1mwMSf6aFBQ=";
})
