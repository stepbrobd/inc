{ stdenvNoCC
, fetchzip
, nodejs
, makeBinaryWrapper
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "0.4.0";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-1P4pQlaTxRsl+5p1kG5aFepa/WTBqc6V7tstowwIZnA=";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/cf
    cp -r bin dist package.json $out/share/cf/

    makeWrapper ${nodejs}/bin/node $out/bin/cf \
      --add-flags $out/share/cf/bin/cf

    runHook postInstall
  '';
})
