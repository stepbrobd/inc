{ inputs, stdenv }: inputs.ranet3.packages.${stdenv.hostPlatform.system}.default
