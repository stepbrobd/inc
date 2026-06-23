{ buildDunePackage
, fetchzip
, base64
, eio
, eio_main
, iso8601
, menhir
, menhirLib
, xmlm
}:

buildDunePackage (finalAttrs: {
  pname = "plist-xml";
  version = "0.5.1";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://github.com/alan-j-hu/ocaml-plist-xml/releases/download/${finalAttrs.version}/plist-xml-${finalAttrs.version}.tbz";
    hash = "sha256-rHPIQHCJKuiHmdPBrnIG12oLlv16j82hBQtt4Yr282E=";
  };

  env.DUNE_CACHE = "disabled";

  nativeBuildInputs = [
    menhir
  ];

  propagatedBuildInputs = [
    base64
    iso8601
    menhirLib
    xmlm
  ];

  doCheck = true;

  checkInputs = [
    eio
    eio_main
  ];
})
