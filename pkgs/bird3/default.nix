{ pkgs
, pkgsPrev ? pkgs # `pkgsPrev` only provided in overlays
, fetchpatch2
}:

pkgsPrev.bird3.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    # rtt: https://github.com/nickcao/bird
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/2912d03c99f99bbe2f7d5041b43a551d3156ce93.patch";
      hash = "sha256-osVfPQAw5qcLhirGtSZDSUA8/ZosJNz1utwhO87sL8c=";
    })
    # https://github.com/nickcao/flakes/blob/master/pkgs/bird-babel-rtt/fix-vrf-if-delete-notification.patch
    (fetchpatch2 {
      url = "https://raw.githubusercontent.com/nickcao/flakes/3358dc18efa4478f5eef69803d6e38fbbc4fe248/pkgs/bird-babel-rtt/fix-vrf-if-delete-notification.patch";
      hash = "sha256-Deyz+6kAxlQr5sDBEnKY4KbeafDHzw+RJHm9G9MkypM=";
    })
  ];
})
