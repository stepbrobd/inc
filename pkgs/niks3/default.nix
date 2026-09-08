{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-dAarYako0R2CQG+t03jSSpWPkP5vCFpyrMssTGKOQn0=";
}
