{ lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;

  cfg = config.services.desktopManager;

  # gtkgreet style
  style = pkgs.writeText "gtk.css" ''
    @import url("${pkgs.nordic}/share/themes/Nordic/gtk-3.0/gtk.css");
    window {
      background-image: url("${lib.blueprint.users.ysun.meta.wallpapersDir}/nord.jpg");
      background-size: cover;
      background-position: center;
    }
  '';
in
{
  options.services.desktopManager = {
    enabled = mkOption {
      type = with types; nullOr (enum [ "niri" ]);
      default = null;
      example = "niri";
      description = ''
        Choose:
        - null (or nothing) -> no desktop manager
        - niri
      '';
    };
  };

  config = mkIf (cfg.enabled != null) (mkMerge [
    {
      boot.initrd.systemd.enable = true;

      # disable boot logs when using a desktop manager
      boot.consoleLogLevel = 0;
      boot.kernelParams = [
        "quiet"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "vt.global_cursor_default=0"
      ];
    }

    # xdg
    {
      xdg.portal = {
        enable = true;
        lxqt.enable = true;
        wlr.enable = true;
        config.common.default = "*";
      };
    }

    # yubikey
    {
      services.pcscd.enable = true;

      services.udev.packages = [ pkgs.yubikey-personalization ];

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    }

    # basic stuff
    {
      hardware.i2c.enable = true;

      networking.networkmanager.wifi.powersave = lib.mkForce false;
      boot.extraModprobeConfig = ''
        options iwlwifi power_save=0
        options iwlmvm power_scheme=1
      '';

      environment.variables = {
        GDK_BACKEND = "wayland";
        LIBSEAT_BACKEND = "logind";
        MOZ_ENABLE_WAYLAND = 1;
        MOZ_WEBRENDER = 1;
        NIXOS_OZONE_WL = 1;
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
        SDL_VIDEODRIVER = "wayland";
        _JAVA_AWT_WM_NONREPARENTING = 1;
      };

      # locker
      security.pam.services.login.enableGnomeKeyring = true;
      security.pam.services.greetd.enableGnomeKeyring = true;
      security.pam.services.greetd.fprintAuth = false;
      security.pam.services.login.fprintAuth = false;

      # gnome polkit and keyring
      security.polkit.enable = true;
      services = {
        dbus.packages = with pkgs; [ gcr ];
        gnome.gnome-keyring.enable = true;
      };
    }

    (mkIf (cfg.enabled == "niri") {
      programs.niri.enable = true;

      # login manager gtkgreet
      services.greetd = {
        enable = true;
        settings.default_session = {
          user = "greeter";
          command = lib.concatStringsSep " " [
            "${pkgs.cage}/bin/cage"
            "-s"
            "-d"
            "-m"
            "last"
            "--"
            "${pkgs.gtkgreet}/bin/gtkgreet"
            "-s"
            "${style}"
            "-c"
            "niri-session"
          ];
        };
      };
    })
  ]);
}
