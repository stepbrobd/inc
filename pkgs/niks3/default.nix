{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-dth35zNmMFPKOopJ7giAmp91lXLtjP80XNBcV+spUxY=";
})
