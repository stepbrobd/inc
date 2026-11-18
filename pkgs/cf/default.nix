{ stdenvNoCC
, fetchzip
, nodejs
, makeBinaryWrapper
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "1.0.0-rc.1";

  passthru.autobump = true;
  passthru.autobumpArgs = [ "--version=unstable" ];

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-bz6pc+ZXwKhd7CD3Vt815DzsoPCuSkEs2PA8GWK76zA=";
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
