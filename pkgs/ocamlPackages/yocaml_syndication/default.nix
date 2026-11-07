{ buildDunePackage
, fmt
, logs
, mdx
, ppx_expect
, qcheck
, qcheck-alcotest
, yocaml
}:

buildDunePackage {
  pname = "yocaml_syndication";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    yocaml
  ];

  doCheck = true;

  nativeCheckInputs = [
    mdx.out
  ];

  checkInputs = [
    fmt
    (mdx.override { inherit logs; })
    ppx_expect
    qcheck
    qcheck-alcotest
  ];
}

