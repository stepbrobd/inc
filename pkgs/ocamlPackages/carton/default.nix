{ buildDunePackage
, fetchzip
, bstr
, cachet
, checkseum
, decompress
, duff
, logs
, ohex
, optint
}:

buildDunePackage (finalAttrs: {
  pname = "carton";
  version = "1.2.0";

  src = fetchzip {
    url = "https://github.com/robur-coop/carton/releases/download/${finalAttrs.version}/carton-${finalAttrs.version}.tbz";
    hash = "sha256-W+S/ICD7vHRQOb0dNEI6SZbBW4QJQs46ARxWf1WZ6Ps=";
  };

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    bstr
    cachet
    checkseum
    decompress
    duff
    logs
    ohex
    optint
  ];

  doCheck = true;
})
