{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    gtk = {
      enable = true;
      gtk4.theme = config.gtk.theme;

      theme = {
        package = pkgs.nordic;
        name = "Nordic";
      };

      cursorTheme = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 24;
      };
    };

    home.pointerCursor = {
      size = 24;

      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors";

      gtk.enable = true;
      x11.enable = true;
    };
  };
}
