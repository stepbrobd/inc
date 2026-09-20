{ config, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    package = pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [ modernz thumbfast ];
    };
  };

  home.packages = with pkgs; [
    ffmpeg
    miruro
    yt-dlp
  ];

  xdg.configFile."carapace/choices/miruro".text = "miruro/cobra@bridge\n";
  xdg.configFile."miruro/config.toml".source = (pkgs.formats.toml { }).generate "miruro.toml" {
    lang = "en";
    dub = false;
    quality = "best";
    provider = "hop:soft";
    download = "${config.home.homeDirectory}/Videos";
  };
}
