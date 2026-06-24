{ pkgsPrev, fetchpatch2 }:

pkgsPrev.nixVersions.latest.appendPatches [
  (fetchpatch2 {
    url = "https://github.com/stepbrobd/nix/commit/8cddad594dee347882b4e589e759b049495d3597.patch";
    hash = "sha256-ThYo0hsNWKowVz3guhJHgxrRzDI4euw5BLZ3L3RTVgY=";
  })
  (fetchpatch2 {
    url = "https://github.com/stepbrobd/nix/commit/49baeb9b817e15305915f02aed876fefb440b26d.patch";
    hash = "sha256-qNFD2BajP+JGAiU3rRbNDJwjezrpzWNaRAoYsgqH/lk=";
  })
]
