{ buildDunePackage
, liquid_ml
, logs
, mdx
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_liquid";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    liquid_ml
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
