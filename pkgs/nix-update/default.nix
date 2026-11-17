{ pkgsPrev, fetchpatch2 }:

# TODO: FIXME: https://github.com/mic92/nix-update/pull/692
pkgsPrev.nix-update.overridePythonAttrs (prev: {
  patches = (prev.patches or [ ]) ++ [
    (fetchpatch2 {
      url = "https://github.com/mic92/nix-update/commit/d545c1fad667e573128cad0db55fdc77134a4d3c.patch";
      hash = "sha256-2YkXzaoZWxmxvZzIigdyjvCyx1uIO7OQW0GtuGRTyF8=";
    })
  ];
})
