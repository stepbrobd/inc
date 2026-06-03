{ pkgsPrev, fetchpatch2 }:

pkgsPrev.nixVersions.latest.appendPatches [
  (fetchpatch2 {
    url = "https://github.com/stepbrobd/nix/commit/69037d4d3cb4eac58f3101ea359418a1cf3468e5.patch";
    hash = "sha256-ThYo0hsNWKowVz3guhJHgxrRzDI4euw5BLZ3L3RTVgY=";
  })
]
