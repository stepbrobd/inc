{ buildDunePackage
, logs
, mdx
, otoml
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_otoml";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    otoml
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
