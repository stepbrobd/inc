{ pkgsPrev, fetchpatch2 }:

pkgsPrev.nixVersions.git.appendPatches [
  (fetchpatch2 {
    url = "https://github.com/stepbrobd/nix/commit/49baeb9b817e15305915f02aed876fefb440b26d.patch";
    hash = "sha256-qNFD2BajP+JGAiU3rRbNDJwjezrpzWNaRAoYsgqH/lk=";
  })
]
