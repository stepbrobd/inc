{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) elem head mkIf mkMerge mkOption types;

  cfg = config.services.desktopManager;
in
{
  imports = [
    inputs.mango.nixosModules.mango
    inputs.noctalia-greeter.nixosModules.default
  ];

  options.services.desktopManager = {
    enabled = mkOption {
      default = [ ];
      type = with types; listOf (enum [
        "mango"
        "niri"
      ]);
      description = ''
        Desktop sessions to enable:
        - [ ] (or nothing) -> no desktop manager
        - mango
        - niri
        All listed sessions show up in the greeter menu, the first one is the default session.
      '';
    };
  };

  config = mkIf (cfg.enabled != [ ]) (mkMerge [
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
        wlr = {
          enable = true;
          settings.screencast = {
            chooser_type = "dmenu";
            chooser_cmd = ''${lib.getExe pkgs.noctalia} dmenu -p "Select screen/window"'';
          };
        };
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
      services.speechd.enable = false;

      hardware.i2c.enable = true;

      environment.systemPackages = [ pkgs.iw ];

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
      # security.pam.services.polkit-1.fprintAuth = false;

      # gnome polkit and keyring
      security.polkit.enable = true;
      services.gnome.gnome-keyring.enable = true;
    }

    # greeter
    {
      # session discovery
      # /run/current-system/sw/share/wayland-sessions
      environment.pathsToLink = [ "/share/wayland-sessions" ];

      programs.noctalia-greeter = {
        enable = true;
        package = pkgs.noctalia-greeter;
        passwordless-sync-users = [ "ysun" ];
        settings = {
          session.default = head cfg.enabled;
          user.default = "ysun";
          keyboard.layout = "us";
          cursor = {
            theme = "Nordzy-cursors";
            path = "${pkgs.nordzy-cursor-theme}/share/icons";
            size = 24;
          };
        };
      };
    }

    # wm
    {
      programs.niri.enable = elem "niri" cfg.enabled;
      programs.mango.enable = elem "mango" cfg.enabled;
    }

    # vm test?
    {
      virtualisation.vmVariant.virtualisation = {
        cores = 4;
        memorySize = 4096;
        qemu.options = [
          "-vga none"
          "-device virtio-gpu-gl-pci"
          "-display gtk,gl=on"
        ];
      };
    }
  ]);
}
