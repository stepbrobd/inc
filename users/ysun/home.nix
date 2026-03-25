{ config
, inputs
, lib
, osConfig
, pkgs
, ...
}:

let
  nixvim = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nixvim;
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
    # linux only and when kde plasma is enabled
    ++ (lib.optionals (pkgs.stdenv.isLinux && osConfig.services.desktopManager.enabled != null) [
    beeper
    cfspeedtest
    cider-2
    comma
    discord # (discord.override { withEquicord = true; }) nixpkgs#430391
    epiphany
    gitleaks
    miroir
    monocle
    mpv
    nix-output-monitor
    nixvim
    obs-studio
    (osu-lazer-bin.override { nativeWayland = true; })
    pinentry-all
    remmina
    ripgrep
    slack
    stepbrobd
    zoom-us
    zotero
    # yt-dlp
  ])
    # darwin only
    ++ (lib.optionals pkgs.stdenv.isDarwin [
    cfspeedtest
    cocoapods
    comma
    gitleaks
    miroir
    monocle
    nix-output-monitor
    nixvim
    pinentry_mac
    ripgrep
    stepbrobd
    # yt-dlp
  ]);

  home.activation.hushlogin = lib.hm.dag.entryAnywhere ''
    $DRY_RUN_CMD touch ${config.home.homeDirectory}/.hushlogin
  '';
}
