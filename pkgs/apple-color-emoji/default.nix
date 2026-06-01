{ stdenvNoCC
, fetchurl
, installFonts
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "apple-color-emoji";
  version = "macos-26-20260219-2aa12422";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${finalAttrs.version}/AppleColorEmoji-Linux.ttf";
    hash = "sha256-U1oEOvBHBtJEcQWeZHRb/IDWYXraLuo0NdxWINwPUxg=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    install -Dm755 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
  '';

  meta.homepage = "https://github.com/samuelngs/apple-emoji-ttf";
})
