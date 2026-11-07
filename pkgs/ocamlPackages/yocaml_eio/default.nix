{ buildDunePackage
, cohttp-eio
, eio
, eio_main
, logs
, mdx
, ppx_expect
, yocaml
, yocaml_runtime
}:

buildDunePackage {
  pname = "yocaml_eio";

  inherit (yocaml) version src;

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    cohttp-eio
    eio
    eio_main
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
