{ stdenv, pkgsPrev }:

if stdenv.isDarwin
then
  pkgsPrev.alacritty.overrideAttrs
    (oldAttrs: {
      postInstall = oldAttrs.postInstall
        + ''
        rm -f $out/Applications/Alacritty.app/Contents/Resources/alacritty.icns
        cp ${./alacritty.icns} $out/Applications/Alacritty.app/Contents/Resources/alacritty.icns
      '';
    })
else pkgsPrev.alacritty
