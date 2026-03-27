{ lib, ... }:

{ pkgs, ... }:

{
  # required by nix-darwin system activation
  # remove after nix-darwin migrated modules either to `users.users` namespace
  # or moved to home-manager
  system.primaryUser = "ysun";

  nix.enable = true;

  services.ntpd-rs = {
    enable = true;
    settings.source = lib.map
      (s: {
        mode = "nts";
        address = s;
        ntp-version = "auto";
      })
      [
        lib.blueprint.services.ntpd-rs.domain
        "time.cloudflare.com"
        "virginia.time.system76.com"
        "ohio.time.system76.com"
        "oregon.time.system76.com"
        "paris.time.system76.com"
        "brazil.time.system76.com"
        "ntppool1.time.nl"
        "ntppool2.time.nl"
        # https://experimental.ntspooltest.org/use
        "0.ke.experimental.ntspooltest.org"
        "1.ke.experimental.ntspooltest.org"
        "2.ke.experimental.ntspooltest.org"
        "3.ke.experimental.ntspooltest.org"
      ];
  };

  environment.systemPackages = [ pkgs.iproute2mac ];

  networking.applicationFirewall = {
    enable = true;
    blockAllIncoming = false;
    enableStealthMode = false;
    allowSigned = true;
    allowSignedApp = true;
  };

  system.defaults = {
    dock = {
      autohide = true;
      tilesize = 64;
      largesize = 64;
      minimize-to-application = true;
      show-recents = true;
      mru-spaces = false;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      # check home-manager modules and homebrew config first
      # before adding/removing here
      persistent-apps = [
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        "/Applications/HEY.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Reminders.app"
      ];
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      CreateDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    loginwindow = {
      # https://mynixos.com/nix-darwin/options/system.defaults.loginwindow
      GuestEnabled = false;
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
