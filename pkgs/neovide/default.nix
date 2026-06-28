{ stdenv, pkgsPrev }:

if stdenv.isDarwin
then
  pkgsPrev.neovide.overrideAttrs
    (oldAttrs: {
      postInstall = oldAttrs.postInstall
        + ''
        rm -f $out/Applications/Neovide.app/Contents/Resources/Neovide.icns
        cp ${./neovide.icns} $out/Applications/Neovide.app/Contents/Resources/Neovide.icns
      '';
    })
else pkgsPrev.neovide
