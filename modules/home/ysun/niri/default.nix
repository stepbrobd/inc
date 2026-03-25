{ inputs, lib, ... }:

{ pkgs
, osConfig ? { services.desktopManager.enabled = null; }
, ...
}:

let
  isNiri = osConfig.services.desktopManager.enabled == "niri";
in
{
  # imports = [ inputs.self.homeManagerModules.ysun.noctalia ];

  config = lib.mkIf isNiri {
    home.packages = with pkgs; [
      brightnessctl
      dunst
      gnome-keyring
      gtklock
      networkmanagerapplet
      pavucontrol
      playerctl
      rofi
      wireplumber
    ];

    gtk = {
      enable = true;

      theme = {
        package = pkgs.nordic;
        name = "Nordic";
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

    xdg.configFile."niri/config.kdl".text = ''
      input {
        keyboard {
          xkb {
            layout "us"
          }
        }
        touchpad {
          tap
          natural-scroll
          scroll-method "two-finger"
        }
        mouse {
          natural-scroll
        }
        focus-follows-mouse max-scroll-amount="0%"
      }

      output "eDP-1" {
        scale 1.5
      }

      layout {
        gaps 4

        border {
          width 2
          active-color "#4c566a"
          inactive-color "#2e3440"
        }

        default-column-width { proportion 0.5; }
      }

      window-rule {
        geometry-corner-radius 8 8 8 8
        clip-to-geometry true
      }

      prefer-no-csd

      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      cursor {
        xcursor-theme "Nordzy-cursors"
        xcursor-size 24
      }

      environment {
        GDK_SCALE "1"
        ELM_SCALE "1"
        QT_SCALE_FACTOR "1"
        XCURSOR_SIZE "24"
      }

      spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "gnome-keyring-daemon" "--start" "--components=pkcs11,secrets,ssh"
      spawn-at-startup "nm-applet" "--indicator"
      spawn-at-startup "dunst"
      spawn-at-startup "waybar"
      spawn-at-startup "fcitx5" "-d"

      binds {
        // terminal
        Mod+T { spawn "alacritty"; }
        // sound control
        Mod+S { spawn "pavucontrol"; }
        // app launcher
        Mod+Space { spawn "sh" "-c" "pgrep -x rofi > /dev/null && pkill -x rofi || rofi -show-icons -combi-modi window,drun,run,ssh -show combi"; }

        // window management
        Mod+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+Z { toggle-window-floating; }
        Mod+A { center-column; }
        Mod+X { consume-or-expel-window-left; }
        Mod+M { quit; }

        // focus
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-or-workspace-up; }
        Mod+J { focus-window-or-workspace-down; }

        // move window
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+J { move-window-down; }

        // move workspace to monitor
        Mod+Left { move-workspace-to-monitor-left; }
        Mod+Right { move-workspace-to-monitor-right; }

        // resize
        Mod+Ctrl+Left { set-column-width "-5%"; }
        Mod+Ctrl+Right { set-column-width "+5%"; }
        Mod+Ctrl+Up { set-window-height "-5%"; }
        Mod+Ctrl+Down { set-window-height "+5%"; }

        // workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }

        Mod+Ctrl+1 { move-window-to-workspace 1; }
        Mod+Ctrl+2 { move-window-to-workspace 2; }
        Mod+Ctrl+3 { move-window-to-workspace 3; }
        Mod+Ctrl+4 { move-window-to-workspace 4; }
        Mod+Ctrl+5 { move-window-to-workspace 5; }
        Mod+Ctrl+6 { move-window-to-workspace 6; }
        Mod+Ctrl+7 { move-window-to-workspace 7; }
        Mod+Ctrl+8 { move-window-to-workspace 8; }
        Mod+Ctrl+9 { move-window-to-workspace 9; }
        Mod+Ctrl+0 { move-window-to-workspace 10; }

        // lock screen
        Ctrl+Super+Q { spawn "gtklock" "--daemonize"; }

        // media keys
        XF86AudioMute { spawn "sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && dunstify --timeout=1000 --replace=1 \"Volume: Mute/Unmute\""; }
        XF86AudioRaiseVolume { spawn "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && dunstify --timeout=1000 --replace=1 \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\""; }
        XF86AudioLowerVolume { spawn "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && dunstify --timeout=1000 --replace=1 \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\""; }
        XF86AudioPrev { spawn "sh" "-c" "playerctl previous && dunstify --timeout=1000 --replace=1 \"Media: Previous\""; }
        XF86AudioPlay { spawn "sh" "-c" "playerctl play-pause && dunstify --timeout=1000 --replace=1 \"Media: Play/Pause\""; }
        XF86AudioNext { spawn "sh" "-c" "playerctl next && dunstify --timeout=1000 --replace=1 \"Media: Next\""; }
        XF86MonBrightnessUp { spawn "sh" "-c" "brightnessctl set 5%+ && dunstify --timeout=1000 --replace=1 \"Brightness: $(brightnessctl get)\""; }
        XF86MonBrightnessDown { spawn "sh" "-c" "brightnessctl set 5%- && dunstify --timeout=1000 --replace=1 \"Brightness: $(brightnessctl get)\""; }

        // screenshots (niri built-in)
        Mod+Shift+3 { screenshot-screen; }
        Mod+Shift+4 { screenshot-window; }
        Mod+Shift+5 { screenshot; }
      }
    '';
  };
}
