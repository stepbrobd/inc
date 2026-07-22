{ inputs, stdenv }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3.overrideAttrs (prev: {
  src = inputs.niks3.outPath;
  vendorHash = "sha256-o4/CrNKiE933ydDOhKz65n6B+guYpioQz+MTMc47iCo=";
})
