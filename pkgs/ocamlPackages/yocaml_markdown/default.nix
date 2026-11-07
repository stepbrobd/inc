{ buildDunePackage
, cmarkit
, hilite
, logs
, mdx
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_markdown";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    cmarkit
    hilite
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
