{ inputs, stdenv }:

inputs.colmena.packages.${stdenv.hostPlatform.system}.colmena.overrideAttrs (prev: {
  patches = prev.patches or [ ] ++ [ ./detached-activation.patch ];
})
