{ config
, lib
, osConfig
, pkgs
, ...
}:

let
  hasTag = lib.hasTag osConfig.networking.hostName;
  isGraphical = hasTag "graphical";
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.stateVersion = "25.05";

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      setSessionVariables = true;
      createDirectories = true;
      extraConfig.WORKSPACE = "${config.home.homeDirectory}/Workspace";
    };
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    mimeApps = rec {
      enable = true;
      associations.added = defaultApplications;
      defaultApplications = {
        "x-scheme-handler/discord" = [ "discord.desktop" ];
        "x-scheme-handler/slack" = [ "slack.desktop" ];
      };
    };
  };

  home = {
    username = "ysun";
    homeDirectory =
      if pkgs.stdenv.isLinux then
        lib.mkDefault "/home/ysun"
      else if pkgs.stdenv.isDarwin then
        lib.mkDefault "/Users/ysun"
      else
        abort "Unsupported OS";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    TERM = "alacritty";
    COLORTERM = "truecolor";
    # GOROOT = "${pkgs.go}/share/go"; # set only in direnv
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/pkg/mod";
  };

  home.packages = with pkgs; [ ]
    ++ (lib.optionals (isGraphical || isDarwin) [
    cfspeedtest
    colmena
    comma
    gitleaks
    miroir
    monocle
    nix-output-monitor
    nixvim
    ripgrep
  ])
    ++ (lib.optionals isGraphical [
    beeper
    cider-2
    discord # (discord.override { withEquicord = true; }) nixpkgs#430391
    epiphany
    mpv
    obs-studio
    (osu-lazer-bin.override { nativeWayland = true; })
    pinentry-all
    remmina
    slack
    zoom-us
    zotero
    # yt-dlp
  ])
    ++ (lib.optionals isDarwin [
    cocoapods
    pinentry_mac
    # yt-dlp
  ]);

  home.activation.hushlogin = lib.hm.dag.entryAnywhere ''
    $DRY_RUN_CMD touch ${config.home.homeDirectory}/.hushlogin
  '';
}
