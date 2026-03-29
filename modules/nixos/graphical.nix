{ inputs, lib, ... }:

{ config, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
in
{
  imports = with inputs.self.nixosModules; [
    audio
    desktop
    fonts
    i18n
    wayvnc
  ];

  config = lib.mkIf (hasTag "graphical") {
    services.desktopManager.enabled = lib.mkDefault (
      if hasTag "hyprland" then "hyprland"
      else if hasTag "niri" then "niri"
      else null
    );
  };
}
