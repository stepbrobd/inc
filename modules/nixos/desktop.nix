{ lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;

  cfg = config.services.desktopManager;
in
{
  options.services.desktopManager = {
    enabled = mkOption {
      type = with types; nullOr (enum [ "hyprland" "niri" ]);
      default = null;
      example = "niri";
      description = ''
        Choose:
        - null (or nothing) -> no desktop manager
        - hyprland
        - niri
      '';
    };
  };

  config = mkIf (cfg.enabled != null) (mkMerge [
    # disable boot logs when using a desktop manager
    {
      boot = {
        kernelParams = [ "quiet" ];
        initrd.systemd.enable = true;
        plymouth = {
          enable = true;
          theme = "mac-style";
          themePackages = [ pkgs.mac-style-plymouth ];
          font = "${pkgs.noto-fonts}/share/fonts/noto/NotoSans.ttf";
        };
      };
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

    # gpg
    { programs.gnupg.agent.enable = true; }

    # basic stuff
    {
      networking.networkmanager.wifi.powersave = lib.mkForce false;
      boot.extraModprobeConfig = ''
        options iwlwifi power_save=0
        options iwlmvm power_scheme=1
      '';

      security.pam.services.login.enableGnomeKeyring = true;

      services = {
        dbus.packages = with pkgs; [ gcr ];
        gnome.gnome-keyring.enable = true;
      };
    }

    (mkIf (cfg.enabled == "hyprland") {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      environment.systemPackages = [ pkgs.hyprland-qtutils ];

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

      # login manager: use gtkgreet, and use gtklock for locker
      services.greetd = {
        enable = true;
        settings.default_session =
          let
            style = pkgs.writeText "gtk.css" ''
              @import url("${pkgs.nordic}/share/themes/Nordic/gtk-3.0/gtk.css");
              window {
                background-image: url("${../home/ysun/noctalia/wallpaper.jpg}");
                background-size: cover;
                background-position: center;
              }
            '';
          in
          {
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
              "start-hyprland"
            ];
          };
      };

      # locker
      security.pam.services.gtklock = { };

      # gnome polkit and keyring are used for hyprland sessions
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;
    })

    (mkIf (cfg.enabled == "niri") {
      programs.niri.enable = true;

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

      # login manager: use gtkgreet, and use gtklock for locker
      services.greetd = {
        enable = true;
        settings.default_session =
          let
            style = pkgs.writeText "gtk.css" ''
              @import url("${pkgs.nordic}/share/themes/Nordic/gtk-3.0/gtk.css");
              window {
                background-image: url("${../home/ysun/noctalia/wallpaper.jpg}");
                background-size: cover;
                background-position: center;
              }
            '';
          in
          {
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

      security.pam.services.gtklock = { };
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;
    })

  ]);
}
