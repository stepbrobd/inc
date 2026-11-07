{ buildDunePackage
, logs
, mdx
, ppx_expect
, yaml
, yocaml
}:

buildDunePackage {
  pname = "yocaml_yaml";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    yaml
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
