{ lib
, stdenvNoCC
, fetchzip
, installFonts
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "furifont";
  version = "0.5.1";

  passthru.autobump = true;

  src = fetchzip {
    stripRoot = false;
    url = "https://github.com/antfu/furifont/releases/download/v${finalAttrs.version}/Furifont.zip";
    hash = "sha256-WJdtDWLR6v0eS+WVVho5NMHFXDONnbdzkRKY8weWqVY=";
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
