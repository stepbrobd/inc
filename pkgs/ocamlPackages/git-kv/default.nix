{ buildDunePackage
, fetchzip
, alcotest
, base64
, bstr
, carton
, carton-git-lwt
, cstruct
, digestif
, emile
, encore
, fmt
, fpath
, hxd
, ke
, logs
, lwt
, mimic
, mirage-kv
, mirage-ptime
, psq
, ptime
, uri
}:

buildDunePackage (finalAttrs: {
  pname = "git-kv";
  version = "0.2.3";

  # FIXME: TODO: disable for now due to dependency type changes
  passthru.autobump = false;

  src = fetchzip {
    url = "https://github.com/robur-coop/git-kv/releases/download/v${finalAttrs.version}/git-kv-${finalAttrs.version}.tbz";
    hash = "sha256-iFSxZkDRTxmTmuAjzB4o+LylOm8ExrtFbptW7jzA2l4=";
  };

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    base64
    bstr
    carton
    carton-git-lwt
    cstruct
    digestif
    emile
    encore
    fmt
    fpath
    hxd
    ke
    logs
    lwt
    mimic
    mirage-kv
    mirage-ptime
    psq
    ptime
    uri
  ];

  doCheck = true;

  checkInputs = [
    alcotest
  ];
})
