{ lib, ... }:

{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        startup_mode = "Windowed";
        padding = {
          x = 4;
          y = 4;
        };
        decorations =
          if pkgs.stdenv.isLinux then
            lib.mkDefault "None"
          else if pkgs.stdenv.isDarwin then
            lib.mkDefault "Buttonless"
          else
            abort "Unsupported OS";
      };

      font = {
        size = 12.00;
        normal = {
          family = "IntoneMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "IntoneMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "IntoneMono Nerd Font";
          style = "Italic";
        };
        bold_italic = {
          family = "IntoneMono Nerd Font";
          style = "Bold Italic";
        };
      };

      keyboard.bindings = [
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
        {
          key = "Up";
          mods = "Control|Shift";
          action = "ScrollPageUp";
        }
        {
          key = "Down";
          mods = "Control|Shift";
          action = "ScrollPageDown";
        }
      ];

      # Nord
      colors = {
        # Primary
        primary = {
          background = "#2e3440";
          foreground = "#d8dee9";
          dim_foreground = "#a5abb6";
        };
        cursor = {
          text = "#2e3440";
          cursor = "#d8dee9";
        };
        vi_mode_cursor = {
          text = "#2e3440";
          cursor = "#d8dee9";
        };
        selection = {
          text = "CellForeground";
          background = "#4c566a";
        };
        search = {
          matches = {
            foreground = "CellBackground";
            background = "#88c0d0";
          };
        };
        # Normal
        normal = {
          black = "#3b4252";
          red = "#bf616a";
          green = "#a3be8c";
          yellow = "#ebcb8b";
          blue = "#81a1c1";
          magenta = "#b48ead";
          cyan = "#88c0d0";
          white = "#e5e9f0";
        };
        # Bright
        bright = {
          black = "#4c566a";
          red = "#bf616a";
          green = "#a3be8c";
          yellow = "#ebcb8b";
          blue = "#81a1c1";
          magenta = "#b48ead";
          cyan = "#8fbcbb";
          white = "#eceff4";
        };
        # Dim
        dim = {
          black = "#373e4d";
          red = "#94545d";
          green = "#809575";
          yellow = "#b29e75";
          blue = "#68809a";
          magenta = "#8c738c";
          cyan = "#6d96a5";
          white = "#aeb3bb";
        };
      };
    };
  };
}
