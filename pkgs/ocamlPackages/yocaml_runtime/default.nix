{ buildDunePackage
, cohttp
, digestif
, fmt
, logs
, magic-mime
, mdx
, ppx_expect
, yocaml
}:

buildDunePackage {
  pname = "yocaml_runtime";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    cohttp
    digestif
    fmt
    logs
    magic-mime
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
