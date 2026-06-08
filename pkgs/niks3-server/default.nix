{ inputs, stdenv, niks3 }:

inputs.niks3.packages.${stdenv.hostPlatform.system}.niks3-server.overrideAttrs {
  inherit (niks3) version src vendorHash;
}
