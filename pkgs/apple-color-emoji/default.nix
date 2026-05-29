{ stdenvNoCC
, fetchurl
, installFonts
}:

stdenvNoCC.mkDerivation {
  pname = "apple-color-emoji";
  version = "macos-26-20260219-561a9d05";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/macos-26-20260219-2aa12422/AppleColorEmoji-Linux.ttf";
    hash = "sha256-U1oEOvBHBtJEcQWeZHRb/IDWYXraLuo0NdxWINwPUxg=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    install -Dm755 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
  '';

  meta.homepage = "https://github.com/samuelngs/apple-emoji-ttf";
}
