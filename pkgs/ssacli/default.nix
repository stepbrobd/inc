{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, dpkg
, writeShellApplication
, coreutils
, curl
, git
, gnugrep
, gnused
, jq
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ssacli";
  version = "6.60-8.0";

  src = fetchurl {
    url = "https://downloads.linux.hpe.com/SDR/repo/mcp/debian/pool/non-free/ssacli-${finalAttrs.version}_amd64.deb";
    hash = "sha256-/C1bt9NDvSom7XGhKEBrohDeKaWhiIDGLGNZpThMnU4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm555 opt/smartstorageadmin/ssacli/bin/ssacli $out/bin/ssacli
    install -Dm555 opt/smartstorageadmin/ssacli/bin/ssascripting $out/bin/ssascripting
    install -Dm444 usr/man/man8/ssacli.8.gz $out/share/man/man8/ssacli.8.gz
    install -Dm444 opt/smartstorageadmin/ssacli/bin/ssacli.license $out/share/doc/ssacli/LICENSE
    install -Dm444 opt/smartstorageadmin/ssacli/bin/ssacli-*.txt $out/share/doc/ssacli/README

    runHook postInstall
  '';

  passthru = {
    autobump = true;
    updater = writeShellApplication {
      name = "ssacli-updater";
      text = lib.readFile ./update.sh;
      runtimeInputs = [
        coreutils
        curl
        git
        gnugrep
        gnused
        jq
      ];
    };
    updateScript = [ (lib.getExe finalAttrs.passthru.updater) ];
  };

  meta = {
    description = "HPE Smart Storage Administrator CLI for Smart Array and SmartRAID controllers";
    homepage = "https://downloads.linux.hpe.com/SDR/project/mcp/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "ssacli";
    platforms = [ "x86_64-linux" ];
  };
})
