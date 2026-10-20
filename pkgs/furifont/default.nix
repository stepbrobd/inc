{ lib
, stdenvNoCC
, fetchzip
, installFonts
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "furifont";
  version = "0.6.1";

  passthru.autobump = true;

  src = fetchzip {
    stripRoot = false;
    url = "https://github.com/antfu/furifont/releases/download/v${finalAttrs.version}/Furifont.zip";
    hash = "sha256-+b84HEVqIrMZD6U7TLwQ56YbZCH4KKiT+8wmk0EWyQw=";
  };

  nativeBuildInputs = [ installFonts ];

  dontInstallWebfonts = true;

  meta = {
    description = "Japanese font that shows furigana by itself";
    homepage = "https://furifont.antfu.me";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
