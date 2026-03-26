{ buildDunePackage
, fetchzip
, alcotest
, bstr
, ca-certs
, digestif
, dns-client-miou-unix
, fmt
, h1
, h2
, happy-eyeballs-miou-unix
, logs
, miou
, mirage-crypto-rng-miou-unix
, tls-miou-unix
}:

buildDunePackage (finalAttrs: {
  pname = "httpcats";
  version = "0.2.1";

  src = fetchzip {
    url = "https://github.com/robur-coop/httpcats/releases/download/v${finalAttrs.version}/httpcats-${finalAttrs.version}.tbz";
    hash = "sha256-ehtwxQGHw8igzI0dy2Zzs+VOqvck/tAUuuJl+jSpVU8=";
  };

  env.DUNE_CACHE = "disabled";

  __darwinAllowLocalNetworking = true;

  propagatedBuildInputs = [
    miou
    h1
    h2
    ca-certs
    bstr
    tls-miou-unix
    dns-client-miou-unix
    happy-eyeballs-miou-unix
  ];

  doCheck = true;

  checkInputs = [
    alcotest
    digestif
    fmt
    logs
    mirage-crypto-rng-miou-unix
  ];
})
