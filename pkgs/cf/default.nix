{ stdenvNoCC
, fetchzip
, nodejs
, makeBinaryWrapper
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "0.5.0";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-/QKb5nDFoXblqKbryfRPvUFx/lTv9SXyugGal025t+I=";
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
