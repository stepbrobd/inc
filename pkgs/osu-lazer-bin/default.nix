{ lib
, pkgsPrev
, fetchurl
, writeShellApplication
, coreutils
, gh
, git
, gnused
, jq
, nativeWayland ? true
}:

(pkgsPrev.osu-lazer-bin.override { inherit nativeWayland; }).overrideAttrs (final: prev: {
  version = "2026.1001.0";

  src = fetchurl {
    url = "https://github.com/ppy/osu/releases/download/${final.version}-tachyon/osu.AppImage";
    hash = "sha256-GQzxljdOhNjnipnS/KNKcO0DaU6D5Ub6mPMpeG4bDdY=";
  };

  meta = prev.meta // { platforms = [ "x86_64-linux" ]; };

  passthru = (prev.passthru or { }) // {
    autobump = true;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "osu-lazer-bin-updater";
        text = lib.readFile ./update.sh;
        runtimeInputs = [
          coreutils
          gh
          git
          gnused
          jq
        ];
      }))
    ];
  };
})
