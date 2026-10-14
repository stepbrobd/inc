{ stdenvNoCC
, fetchzip
, nodejs
, makeBinaryWrapper
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "1.0.0-beta.16";

  passthru.autobump = true;
  passthru.autobumpArgs = [ "--version=unstable" ];

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-S3jjivG3V/fee9Dcut5OXQ6hpsoJ5DXpcrQAQgdzMGU=";
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
