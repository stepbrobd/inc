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

    settings.source = (lib.map
      (s: {
        mode = "nts";
        address = s;
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
        "nts.teambelgium.net"
        "nts.netnod.se"
      ]) ++ [{
      enable-srv-resolution = true;
      mode = "nts-pool";
      address = "srv.sectime.org";
    }];
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
      showAppExposeGestureEnabled = true;
      showMissionControlGestureEnabled = true;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      # check home-manager modules and homebrew config first
      # before adding/removing here
      persistent-apps = [
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/Applications/Things3.app"
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
      # two finger swipe between pages
      AppleEnableSwipeNavigateWithScrolls = true;
      # natural scrolling
      "com.apple.swipescrolldirection" = true;
      # tracking speed
      "com.apple.trackpad.scaling" = 3.0;
    };

    trackpad = {
      Clicking = true; # tap to click
      Dragging = true; # tap and drag
      TrackpadRightClick = true; # two finger secondary click
      TrackpadThreeFingerTapGesture = 0; # look up disabled
      TrackpadThreeFingerDrag = false;

      # two finger
      TrackpadTwoFingerDoubleTapGesture = true; # smart zoom
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3; # notification center

      # three finger
      TrackpadThreeFingerHorizSwipeGesture = 0; # disabled (four finger handles spaces)
      TrackpadThreeFingerVertSwipeGesture = 2; # mission control and app expose

      # four finger
      TrackpadFourFingerHorizSwipeGesture = 2; # swipe between spaces
      TrackpadFourFingerVertSwipeGesture = 2; # mission control and app expose
      TrackpadFourFingerPinchGesture = 2; # pinch launchpad and spread desktop
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
