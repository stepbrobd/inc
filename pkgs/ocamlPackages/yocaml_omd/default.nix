{ buildDunePackage
, logs
, mdx
, omd
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_omd";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    omd
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
