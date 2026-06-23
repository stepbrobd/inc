{ buildDunePackage
, fetchFromGitHub
, cmarkit
, mdx
, textmate-language
}:

buildDunePackage (finalAttrs: {
  pname = "hilite";
  version = "0.5.0";

  passthru.autobump = true;

  src = fetchFromGitHub {
    owner = "patricoferris";
    repo = "hilite";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RgK6FxUc4+OOHQdKfb+mwk4DZcHEIdZsd+6ItcfAoys=";
  };

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    cmarkit
    textmate-language
  ];

  doCheck = true;

  nativeCheckInputs = [
    mdx.bin
  ];

  checkInputs = [
    mdx
  ];
})
