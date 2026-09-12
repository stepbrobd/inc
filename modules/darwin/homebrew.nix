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

    brews = [ "mole" ];

    caskArgs.no_quarantine = null;

    casks = [
      # my own casks
      "stepbrobd/tap/opentabletdriver"
      # sonarworks soundid
      "stepbrobd/tap/soundid-reference"
      # universal audio
      "stepbrobd/tap/ua-connect"

      # "antinote" # i dont really keep note that much
      # "dockdoor" # dont seem to work that well with aerospace
      # "hey-desktop" # fuck this shit
      # "kindavim" # not using as much
      # "lulu" # removed cause too annoying
      # "orion" # too unstable

      "alcove"
      "beeper"
      "betterdisplay"
      "container"
      "discord"
      "google-chrome"
      "imazing-profile-editor"
      "loop"
      "obs"
      "osu"
      "passepartout"
      "slack"
      "stats"
      "tailscale-app"
      "the-unarchiver"
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
      "Parcel" = 375589283;
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
