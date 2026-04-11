{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.mas ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    global = {
      autoUpdate = true;
      brewfile = true;
    };

    taps = [
      # my own taps
      "stepbrobd/tap"
      # universal audio
      "resonative/proaudio"
      # sonarworks soundid
      "lyraphase/av-casks"
      # third-party taps
      "nextfire/tap"
    ];

    brews = [
      # apple music discord rich presence
      # requires deno readline sqlite
      {
        name = "apple-music-discord-rpc";
        start_service = true;
        restart_service = "changed";
      }
      "deno"
      "mole"
      "readline"
      "sqlite"
    ];

    caskArgs.no_quarantine = null;

    casks = [
      # my own casks
      "stepbrobd/tap/opentabletdriver"
      # universal audio
      "resonative/proaudio/ua-connect"
      # sonarworks soundid
      "lyraphase/av-casks/soundid-reference"

      # "lulu" # removed cause too annoying

      "alcove"
      "antinote"
      "beeper"
      "betterdisplay"
      "container"
      "discord"
      "dockdoor"
      "google-chrome"
      "hey-desktop"
      "kindavim"
      "loop"
      "macs-fan-control"
      "notchnook"
      "obs"
      "orion"
      "osu"
      "slack"
      "thaw"
      "webex"
      "yubico-authenticator"
      "zoom"
      "zotero"

      # caldigit, mostly fixing superdrive power issue
      "caldigit-docking-utility"
      "caldigit-thunderbolt-charging"
    ];

    masApps = {
      # utils
      "Apple Configurator" = 1037126344;
      "Dropover" = 1355679052;
      "Flighty" = 1358823008;
      "Folder Preview" = 6698876601;
      "iMazing Profile Editor" = 1487860882;
      "iStat Menus" = 1319778037;
      "Parcel" = 375589283;
      "Passepartout" = 1433648537;
      "Pieoneer" = 6739781207;
      "Pixelmator Pro" = 1289583905;
      "Remote Desktop" = 409907375;
      "ServerCat" = 1501532023;
      "Tailscale" = 1475387142;
      "The Unarchiver" = 425424353;
      "Xcode" = 497799835;
      # safari
      "AdGuard" = 1440147259;
      "Kagi" = 1622835804;
      "Noir" = 1592917505;
      "StopTheMadness" = 6471380298;
      "Tampermonkey" = 6738342400;
      "Vimari" = 1480933944;
      # media
      "Macgo Blu-ray Player Pro" = 1403952861;
      # iwork
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
    };
  };
}
