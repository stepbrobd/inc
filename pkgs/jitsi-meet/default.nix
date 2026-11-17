{ fetchurl
, pkgsPrev
}:

pkgsPrev.jitsi-meet.overrideAttrs (final: prev: {
  version = "1.0.9644";

  src = fetchurl {
    url = "https://download.jitsi.org/jitsi-meet/src/jitsi-meet-${final.version}.tar.bz2";
    hash = "sha256-byfBziQnP20OD0uZhOYaUE7IGfaBEr2i+AXVuAABkxs=";
  };

  patches = [ ./plausible.patch ];

  # use the released web bundle instead of rebuilding it with npm
  env = { };
  nativeBuildInputs = [ ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir "$out"
    mv -- * "$out/"
    runHook postInstall
  '';

  passthru = prev.passthru // {
    autobump = true;
    updateScript = [ ./update.sh "jitsi-meet" ];
  };

  meta = prev.meta // {
    knownVulnerabilities = [ ];
  };
})
