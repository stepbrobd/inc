{ lib
, pkgsPrev
, stdenv
, lld
}:

pkgsPrev.starship.overrideAttrs (prev: {
  nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ lib.optionals stdenv.isDarwin [ lld ];

  env = (prev.env or { }) // lib.optionalAttrs stdenv.isDarwin {
    NIX_CFLAGS_LINK = "-fuse-ld=lld";
  };
})
