{ lib, pkgsPrev, fetchpatch2 }:

# TODO: FIXME: https://github.com/rhysd/actionlint/pull/732
pkgsPrev.actionlint.overrideAttrs (prev: {
  patches = (prev.patches or [ ]) ++ [
    (fetchpatch2 {
      url = "https://github.com/rhysd/actionlint/commit/bdfa15b644bc27b4c5944be36003c0edc9ef41d2.patch";
      hash = "sha256-j5ZuL1JZ1Ab5XusiAy8na/ZLX+0gqHJgE4gJCG25BcY=";
    })
    (fetchpatch2 {
      url = "https://github.com/rhysd/actionlint/commit/b02c24b743cc88a26b280339814eb4ece91c32cb.patch";
      hash = "sha256-33b6zV1pFmrkplaaojfsvGcRbEXVHyhMBRyo8q0fbGQ=";
    })
  ];
})
