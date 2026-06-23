{ buildDunePackage
, fetchzip
, alcotest
, fmt
, logs
, mdx
, ppx_expect
, qcheck
, qcheck-alcotest
}:

buildDunePackage (finalAttrs: {
  pname = "yocaml";
  version = "3.0.0";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://github.com/xhtmlboi/yocaml/releases/download/v${finalAttrs.version}/yocaml-${finalAttrs.version}.tbz";
    hash = "sha256-5mugS5NMspGWzjejMcyCK3dSDLcxWSXyw4FTdsutScg=";
  };

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    logs
  ];

  doCheck = true;

  nativeCheckInputs = [
    mdx.bin
  ];

  checkInputs = [
    alcotest
    fmt
    (mdx.override { inherit logs; })
    ppx_expect
    qcheck
    qcheck-alcotest
  ];
})
