{ buildDunePackage
, httpcats
, logs
, mdx
, ppx_expect
, yocaml
, yocaml_runtime
}:

buildDunePackage {
  pname = "yocaml_unix";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    httpcats
    yocaml
    yocaml_runtime
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
