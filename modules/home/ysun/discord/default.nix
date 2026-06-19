{ pkgs, ... }:

{
  programs.discord = {
    enable = pkgs.stdenv.isLinux;

    settings = {
      BACKGROUND_COLOR = "#2c2d32";
      IS_MAXIMIZED = false;
      IS_MINIMIZED = false;
      SKIP_HOST_UPDATE = true;
      DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
    };
  };

  xdg.mimeApps.associations.added."x-scheme-handler/discord" = [ "discord.desktop" ];
  xdg.mimeApps.defaultApplications."x-scheme-handler/discord" = [ "discord.desktop" ];
}
