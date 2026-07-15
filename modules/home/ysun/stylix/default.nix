{ lib, inputs, ... }:

{ pkgs, ... }:

{
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix.enable = true;
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

    gnome.enable = false;
    kde.enable = false;
    xfce.enable = false;

    neovide.enable = false;
    nixvim.enable = false;
    noctalia-shell.enable = false;
    noctalia.enable = false;
  };
}
