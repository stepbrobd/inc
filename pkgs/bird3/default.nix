{ pkgs
, pkgsPrev ? pkgs # `pkgsPrev` only provided in overlays
, fetchpatch2
}:

pkgsPrev.bird3.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    # link quality algo selection
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/427cf93908cce6a6f9faeab9d53972e324b8d357.patch";
      hash = "sha256-osVfPQAw5qcLhirGtSZDSUA8/ZosJNz1utwhO87sL8c=";
    })
    # iface deletion race
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/1a4d4a81b3e3ca23edad75c027dc3e19ef1947b8.patch";
      hash = "sha256-h6WC/EJr+iA+tZbKlDFJfiRmZP8MnSSyY2cJg+JNMXc=";
    })
  ];
})
