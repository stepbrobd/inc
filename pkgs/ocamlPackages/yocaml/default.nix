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
  version = "3.0.1";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://github.com/xhtmlboi/yocaml/releases/download/v${finalAttrs.version}/yocaml-${finalAttrs.version}.tbz";
    hash = "sha256-jouAHcOyl+CzhEimHXBnpW50wKDdKLEnX4njZl2c81o=";
  };

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    logs
  ];

  doCheck = true;

  nativeCheckInputs = [
    mdx.out
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
