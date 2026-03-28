{ inputs, stdenv }:

inputs.colmena.packages.${stdenv.hostPlatform.system}.colmena.overrideAttrs (prev: {
  patches = prev.patches or [ ] ++ [
    # https://github.com/stepbrobd/colmena/tree/detached
    ./detached-activation.patch
    # rebased on top of detached activation https://github.com/zhaofengli/colmena/pull/319
    ./darwin-colmena.patch
  ];
})
