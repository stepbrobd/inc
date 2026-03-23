{ pkgs
, pkgsPrev ? pkgs # `pkgsPrev` only provided in overlays
, fetchpatch2
}:

pkgsPrev.bird3.overrideAttrs (oldAttrs: {
  patches = oldAttrs ++ [
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/2912d03c99f99bbe2f7d5041b43a551d3156ce93.patch";
      hash = "";
    })
  ];
})
