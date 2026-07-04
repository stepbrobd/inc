{ lib, inputs, ... }:

{ config
, pkgs
, osConfig ? { networking.hostName = ""; }
, ...
}:

let
  cfg = config.programs.noctalia;

  hasTag = lib.hasTag osConfig.networking.hostName;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkMerge [
    (lib.mkIf (hasTag "noctalia") {
      programs.noctalia.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        brightnessctl
        cliphist
        ddcutil
        wl-clipboard
        wireplumber
      ];

      home.sessionVariables.QT_QPA_PLATFORMTHEME = "gtk3";

      gtk = {
        enable = true;
        gtk4.theme = config.gtk.theme;

        theme = {
          package = pkgs.nordic;
          name = "Nordic";
        };

        iconTheme = {
          package = pkgs.nordzy-icon-theme;
          name = "Nordzy-dark";
        };

        cursorTheme = {
          package = pkgs.nordzy-cursor-theme;
          name = "Nordzy-cursors";
          size = 24;
        };
      };

      home.pointerCursor = {
        size = 24;

        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";

        gtk.enable = true;
        x11.enable = true;
      };

      programs.noctalia.settings = {
        audio.enable_overdrive = true;

        bar = {
          order = [ "default" ];
          default = {
            position = "top";
            background_opacity = 0.75;
            scale = 1.25;
            radius = 12;
            margin_edge = 8;
            margin_ends = 8;
            padding = 16;
            widget_spacing = 16;

            start = [ "workspaces" ];
            center = [ ];
            end = [
              "cpu"
              "ram"
              "network_tx"
              "network_rx"
              "battery"
              "control-center"
              "clock"
              "notifications"
            ];
          };
        };

        backdrop = {
          enabled = true;
          blur_intensity = 0.0;
          tint_intensity = 0.0;
        };

        brightness.enable_ddcutil = true;

        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "wallpaper"; }
          { type = "notification"; }
          { type = "caffeine"; }
          { type = "nightlight"; }
        ];

        dock.enabled = false;

        idle = {
          pre_action_fade_seconds = 5.0;
          behavior = {
            lock = {
              action = "lock";
              enabled = true;
              timeout = 300;
            };
            screen-off = {
              action = "screen_off";
              enabled = true;
              timeout = 3600;
            };
          };
        };

        location.auto_locate = true;

        lockscreen = {
          enabled = true;
          fingerprint = true;
          blur_intensity = 0.0;
          tint_intensity = 0.0;
        };

        lockscreen_widgets = {
          enabled = true;
          widget.clock = {
            type = "clock";
            cx = 960.0;
            cy = 256.0;
            box_width = 512.0;
            box_height = 256.0;
            settings = {
              clock_style = "digital";
              format = "{:%H:%M}";
              color = "error";
              shadow = false;
              background = false;
            };
          };
        };

        notification.position = "top_right";

        osd.position = "top_right";

        shell = {
          avatar_path = lib.blueprint.users.ysun.meta.profilePicture;
          clipboard_auto_paste = "off";
          password_style = "random";
          launcher = {
            categories = true;
            session_search = true;
            sort_by_usage = true;
          };
          screenshot.directory = "${config.home.homeDirectory}/Pictures/Screenshots";
        };

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Nord";
        };

        wallpaper = {
          enabled = true;
          directory = lib.blueprint.users.ysun.meta.wallpapersDir;
          fill_mode = "crop";
          transition_duration = 1500;
          automation = {
            enabled = true;
            interval_seconds = 3600;
            order = "random";
          };
        };

        weather = {
          enabled = true;
          unit = "metric";
          effects = false;
        };

        widget = {
          clock = {
            type = "clock";
            format = "{:%a %b %-d %H:%M:%S}";
          };

          control-center = {
            type = "control-center";
            glyph = "adjustments";
          };

          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            show_label = false;
          };
          ram = {
            type = "sysmon";
            stat = "ram_used";
            show_label = false;
          };
          network_rx = {
            type = "sysmon";
            stat = "net_rx";
            show_label = false;
          };
          network_tx = {
            type = "sysmon";
            stat = "net_tx";
            show_label = false;
          };
        };
      };
    })
  ];
}
