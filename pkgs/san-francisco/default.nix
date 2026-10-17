{ lib
, stdenvNoCC
, fetchurl
, _7zz
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
      hash = "sha256-wdDjROut1m62LwP4I3hMzknxeH9WVj+wmPygH8VUE1w=";
    })
    (fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
      hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
    })
    (fetchurl {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
      hash = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
    })
  ];

  nativeBuildInputs = [ _7zz ];

  sourceRoot = ".";
  preUnpack = "mkdir fonts";
  unpackCmd = ''
    7zz x $curSrc -odmg >/dev/null
    7zz x "$(find dmg -name '*.pkg' -type f)" -opkg >/dev/null
    7zz x "$(find pkg -name Payload -type f)" -ogz >/dev/null
    7zz x gz/Payload~ -opayload >/dev/null
    mv payload/Library/Fonts/*.otf fonts/
    rm -R dmg pkg gz payload
  '';

  installPhase = ''
    mkdir -p $out/share/fonts/opentype/{SF\ Compact,SF\ Mono,SF\ Pro,New\ York}
    cp -a fonts/SF-Compact*.otf $out/share/fonts/opentype/SF\ Compact
    cp -a fonts/SF-Mono*.otf $out/share/fonts/opentype/SF\ Mono
    cp -a fonts/SF-Pro*.otf $out/share/fonts/opentype/SF\ Pro
    cp -a fonts/NewYork*.otf $out/share/fonts/opentype/New\ York
  '';

  meta.license = lib.licenses.unfree;
}
