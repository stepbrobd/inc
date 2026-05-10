{ pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    enableGhostscriptFonts = true;

    packages = with pkgs; [
      apple-color-emoji
      font-awesome
      nerd-fonts.intone-mono
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
    ];

    fontconfig = {
      enable = true;

      allowBitmaps = true;
      antialias = true;

      hinting = {
        enable = true;
        style = "full";
      };

      defaultFonts = {
        emoji = [ "Apple Color Emoji" ];
        serif = [
          "Noto Serif"
          "Apple Color Emoji"
        ];
        sansSerif = [
          "Noto Sans"
          "Apple Color Emoji"
        ];
        monospace = [
          "IntoneMono Nerd Font"
          "Apple Color Emoji"
        ];
      };
    };
  };
}
