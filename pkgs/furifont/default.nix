{ lib
, stdenvNoCC
, fetchzip
, installFonts
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "furifont";
  version = "0.6.2";

  passthru.autobump = true;

  src = fetchzip {
    stripRoot = false;
    url = "https://github.com/antfu/furifont/releases/download/v${finalAttrs.version}/Furifont.zip";
    hash = "sha256-Mqh/6ujWDtCZAeO+eQq319L/3itGSjsVqfzUxzvBi64=";
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
