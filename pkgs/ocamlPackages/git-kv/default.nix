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
  version = "0.2.2";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://github.com/robur-coop/git-kv/releases/download/v${finalAttrs.version}/git-kv-${finalAttrs.version}.tbz";
    hash = "sha256-oKEoMDZvtwbKLbO7odEyXXIi5/H0rQWnA8ZM/PaVpyo=";
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
