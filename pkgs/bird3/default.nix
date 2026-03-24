{ pkgs
, pkgsPrev ? pkgs # `pkgsPrev` only provided in overlays
, fetchpatch2
}:

pkgsPrev.bird3.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    # link quality algo selection
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/2912d03c99f99bbe2f7d5041b43a551d3156ce93.patch";
      hash = "sha256-osVfPQAw5qcLhirGtSZDSUA8/ZosJNz1utwhO87sL8c=";
    })
    # iface deletion race
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/36f9f42912a1adc376886de6a569aff38313326b.patch";
      hash = "sha256-h6WC/EJr+iA+tZbKlDFJfiRmZP8MnSSyY2cJg+JNMXc=";
    })
  ];
})
