{ buildDunePackage
, logs
, mdx
, mustache
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_mustache";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    mustache
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
