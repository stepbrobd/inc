{ pkgsPrev, pkg-config, zstd }:

# TODO: FIXME: https://github.com/NixOS/nixpkgs/pull/576484
pkgsPrev.viceroy.overrideAttrs (prev: {
  postPatch = (prev.postPatch or "") + ''
    substituteInPlace src/lib.rs \
      --replace-fail '#![cfg_attr(not(debug_assertions), deny(warnings))]' ""
  '';

  nativeBuildInputs = prev.nativeBuildInputs ++ [ pkg-config ];

  buildInputs = (prev.buildInputs or [ ]) ++ [ zstd ];

  env = (prev.env or { }) // { ZSTD_SYS_USE_PKG_CONFIG = true; };
})
