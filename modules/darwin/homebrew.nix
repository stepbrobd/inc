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

      # "antinote" # i dont really keep note that much
      # "dockdoor" # dont seem to work that well with aerospace
      # "lulu" # removed cause too annoying
      # "orion" # too unstable

      "alcove"
      "beeper"
      "betterdisplay"
      "container"
      "discord"
      "google-chrome"
      "hey-desktop"
      "imazing-profile-editor"
      "kindavim"
      "loop"
      "macs-fan-control"
      "obs"
      "osu"
      "passepartout"
      "slack"
      "stats"
      "tailscale-app"
      "thaw"
      "the-unarchiver"
      "yubico-authenticator"
      "zoom"
      "zotero"

      # caldigit, mostly fixing superdrive power issue
      "caldigit-docking-utility"
      "caldigit-thunderbolt-charging"
    ];


    # spotlight issue
    # only enable this when mas tries to re-download everything
    # currently should be fix in my fork
    # https://github.com/stepbrobd/mas/tree/macos26
    # onActivation.extraEnv.HOMEBREW_BUNDLE_MAS_SKIP = lib.concatStringsSep
    #   " "
    #   (lib.map lib.toString (lib.attrValues config.homebrew.masApps));

    masApps = {
      # utils
      "Apple Configurator" = 1037126344;
      "Dropover" = 1355679052;
      "Flighty" = 1358823008;
      "Folder Preview" = 6698876601;
      "Parcel" = 375589283;
      "Pieoneer" = 6739781207;
      "Pixelmator Pro" = 1289583905;
      "Remote Desktop" = 409907375;
      "ServerCat" = 1501532023;
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
      "Keynote" = 361285480;
      "Numbers" = 361304891;
      "Pages" = 361309726;
    };
  };
}
