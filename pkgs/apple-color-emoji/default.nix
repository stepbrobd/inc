{ stdenvNoCC
, fetchurl
, installFonts
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "apple-color-emoji";
  version = "macos-26-20260218-d5729b24";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${finalAttrs.version}/AppleColorEmoji-Linux.ttf";
    hash = "sha256-TvX+SNSkD+cuikrRoJR+GdT+oH1P6Xh+ufZf4YZQRoA=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    install -Dm755 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
  '';

  meta.homepage = "https://github.com/samuelngs/apple-emoji-ttf";
})
