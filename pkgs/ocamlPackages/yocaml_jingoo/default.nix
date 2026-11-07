{ buildDunePackage
, jingoo
, logs
, mdx
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_jingoo";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    jingoo
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
