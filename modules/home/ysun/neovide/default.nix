{ config, ... }:

{
  programs.neovide = {
    enable = true;

    settings = {
      inherit (config.programs.alacritty.settings) font;

      theme = "auto";
      frame = "none";
      title-hidden = true;
      fork = true;
      tabs = false;
    };
  };
}
