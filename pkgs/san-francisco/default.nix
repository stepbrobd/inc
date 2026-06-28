{ lib
, stdenvNoCC
, fetchurl
, p7zip
}:

stdenvNoCC.mkDerivation {
  pname = "san-francisco";
  version = "0-unstable-2026-05-30";

  src = [
    (fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
      hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
    })
    (fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
      hash = "sha256-/lF6UYS+KQ5m/om4tLbqGFSPztGuFTlJmnEmXjMXJJ8=";
    })
    (fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
      hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
    })
    (fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
      hash = "sha256-YxGk8IQ6TS5hagsFx3US0x0uqVBFnPUmzbW5CZageU8=";
    })
  ];

  sourceRoot = ".";
  preUnpack = "mkdir fonts";
  unpackCmd = ''
    7z x $curSrc >/dev/null
    dir="$(find . -not \( -path ./fonts -prune \) -type d | sed -n 2p)"
    cd $dir 2>/dev/null
    7z x *.pkg >/dev/null
    7z x Payload~ >/dev/null
    mv Library/Fonts/*.otf ../fonts/
    cd ../
    rm -R $dir
  '';

  nativeBuildInputs = [ p7zip ];

  installPhase = ''
    mkdir -p $out/share/fonts/opentype/{SF\ Compact,SF\ Mono,SF\ Pro,New\ York}
    cp -a fonts/SF-Compact*.otf $out/share/fonts/opentype/SF\ Compact
    cp -a fonts/SF-Mono*.otf $out/share/fonts/opentype/SF\ Mono
    cp -a fonts/SF-Pro*.otf $out/share/fonts/opentype/SF\ Pro
    cp -a fonts/NewYork*.otf $out/share/fonts/opentype/New\ York
  '';

  meta.license = lib.licenses.unfree;
}
