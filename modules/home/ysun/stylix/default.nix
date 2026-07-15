{ lib, inputs, ... }:

{ pkgs, ... }:

{
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix.enable = true;
  stylix.overlays.enable = lib.mkForce false;

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  stylix.polarity = "dark";

  stylix.fonts = {
    sizes.terminal = 14;
    monospace = {
      package = pkgs.nerd-fonts.intone-mono;
      name = "IntoneMono Nerd Font";
    };
    serif = {
      package = pkgs.noto-fonts;
      name = "Noto Serif";
    };
    sansSerif = {
      package = pkgs.noto-fonts;
      name = "Noto Sans";
    };
    emoji = {
      package = pkgs.apple-color-emoji;
      name = "Apple Color Emoji";
    };
  };

  home.pointerCursor.enable = pkgs.stdenv.isLinux;
  stylix.cursor = lib.mkIf pkgs.stdenv.isLinux {
    package = pkgs.nordzy-cursor-theme;
    name = "Nordzy-cursors";
    size = 24;
  };

  stylix.icons = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    package = pkgs.nordzy-icon-theme;
    dark = "Nordzy-dark";
  };

  stylix.targets = {
    gtk.enable = pkgs.stdenv.isLinux;
    qt.enable = pkgs.stdenv.isLinux;

    # these weird ass shit theme files gets written even if the app is not enabled
    blender.enable = false;
    eog.enable = false;
    gnome-text-editor.enable = false;
    vencord.enable = false;

    # wtf are these bruh
    gnome.enable = false;
    kde.enable = false;
    xfce.enable = false;

    # inlined or inherited
    neovide.enable = false;
    nixvim.enable = false;
    noctalia-shell.enable = false;
    noctalia.enable = false;
  };
}
