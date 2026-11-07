{ buildDunePackage
, cmarkit
, logs
, mdx
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_cmarkit";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    cmarkit
    yocaml
  ];

  doCheck = true;

  nativeCheckInputs = [
    mdx.out
  ];

  checkInputs = [
    (mdx.override { inherit logs; })
    ppx_expect
  ];
}
