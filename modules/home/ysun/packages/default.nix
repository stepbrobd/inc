{ lib, ... }:

{ pkgs
, osConfig ? { networking.hostName = ""; }
, ...
}:

let
  hasTag = lib.hasTag osConfig.networking.hostName;
  isGraphical = hasTag "graphical";
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  home.packages = with pkgs; [
    # imported to all systems
  ]
  ++ (lib.optionals (isGraphical || isDarwin) [
    # imported to all graphical systems
    cfspeedtest
    colmena
    comma
    gitleaks
    howfastly
    miroir
    monocle
    nix-output-monitor
    python3
    yubikey-manager
  ])
  ++ (lib.optionals isGraphical [
    # imported to graphical linux machines
    beeper
    cider-2
    (obs-studio.override { browserSupport = false; })
    (osu-lazer-bin.override { nativeWayland = true; })
    pinentry-all
    remmina
    zotero
  ])
  ++ (lib.optionals isDarwin [
    # imported only to macos machines
    cocoapods
    pinentry_mac
  ]);
}
