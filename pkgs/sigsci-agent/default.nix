{ lib
, stdenvNoCC
, fetchurl
, versionCheckHook
, writeShellApplication
, coreutils
, curl
, git
, gnused
, jq
}:

let
  base = "https://dl.signalsciences.net/sigsci-agent";
  suffix = lib.optionalString stdenvNoCC.hostPlatform.isAarch64 "_arm64";

  version = "4.83.0";
  hashes = {
    x86_64-linux = "sha256-s1dVyTkBSmYRlg0ukODMixnPVdNsVxy7Tiazzhd78RE=";
    aarch64-linux = "sha256-8cM2Ma4GV2VE65Q0H6ykOB4f1xdEyY982flP6gWlG3A=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sigsci-agent";
  inherit version;

  src = fetchurl {
    url = "${base}/${finalAttrs.version}/linux/sigsci-agent_${finalAttrs.version}${suffix}.tar.gz";
    hash = hashes.${stdenvNoCC.hostPlatform.system};
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 sigsci-agent $out/bin/sigsci-agent
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru = {
    autobump = true;
    updater = writeShellApplication {
      name = "sigsci-agent-updater";
      text = lib.readFile ./update.sh;
      runtimeInputs = [
        coreutils
        curl
        git
        gnused
        jq
      ];
    };
    updateScript = [ (lib.getExe finalAttrs.passthru.updater) ];
  };

  meta = {
    description = "Fastly Next-Gen WAF agent";
    homepage = "https://www.fastly.com/documentation/guides/next-gen-waf/setup-and-configuration/agent-management/";
    changelog = "https://www.fastly.com/documentation/reference/changes/ngwaf-agent/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "sigsci-agent";
    platforms = lib.attrNames hashes;
  };
})
