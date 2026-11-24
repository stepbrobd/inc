{ stdenvNoCC
, fetchzip
, nodejs
, makeBinaryWrapper
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "1.0.0-rc.4";

  passthru.autobump = true;
  passthru.autobumpArgs = [ "--version=unstable" ];

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-/i44q5Mk/wslYOBGv7hWkmM426o6BYBijZJJ6x1aSAk=";
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
