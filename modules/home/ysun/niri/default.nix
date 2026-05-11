{ lib, ... }:

{ pkgs
, osConfig ? { services.desktopManager.enabled = null; }
, ...
}:

let
  isNiri = osConfig.services.desktopManager.enabled == "niri";

  ipc = args: ''spawn "noctalia-shell" "ipc" "call" ${args}'';
in
{
  config = lib.mkIf isNiri {
    home.packages = [ pkgs.gnome-keyring ];

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
          click-method "clickfinger"
          dwt
        }
        mouse {
          natural-scroll
        }
        focus-follows-mouse max-scroll-amount="0%"
      }

      output "eDP-1" {
        scale 1.5
        variable-refresh-rate
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
      spawn-at-startup "noctalia-shell"
      spawn-at-startup "fcitx5" "-d"

      binds {
        // terminal
        Mod+T { spawn "alacritty"; }

        // noctalia shell IPC
        Mod+S        { ${ipc ''"volume" "togglePanel"''}; }
        Mod+Space    { ${ipc ''"launcher" "toggle"''}; }
        Mod+M        { ${ipc ''"sessionMenu" "toggle"''}; }
        Ctrl+Super+Q { ${ipc ''"lockScreen" "lock"''}; }

        // window management
        Mod+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+Z { toggle-window-floating; }
        Mod+A { center-column; }
        Mod+X { consume-or-expel-window-left; }

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
        Mod+Left  { move-workspace-to-monitor-left; }
        Mod+Right { move-workspace-to-monitor-right; }

        // resize column width (preserved from hyprland)
        Mod+Ctrl+Left  { set-column-width "-5%"; }
        Mod+Ctrl+Right { set-column-width "+5%"; }

        // resize window height (moved off Mod+Ctrl+Up/Down to free that for overview)
        Mod+Ctrl+Shift+Up   { set-window-height "-5%"; }
        Mod+Ctrl+Shift+Down { set-window-height "+5%"; }

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

        // mouse drag/resize, niri have these as hardcoded gestures on
        // Mod+LeftMouse (move floating) and Mod+RightMouse (resize floating)
        // they cannot be rebound to Mod+Ctrl like hyprland's bindm did

        // overview
        Mod+Ctrl+Up { toggle-overview; }

        // media keys via noctalia IPC
        XF86AudioMute        { ${ipc ''"volume" "muteOutput"''}; }
        XF86AudioRaiseVolume { ${ipc ''"volume" "increase"''}; }
        XF86AudioLowerVolume { ${ipc ''"volume" "decrease"''}; }
        XF86AudioPrev        { ${ipc ''"media" "previous"''}; }
        XF86AudioPlay        { ${ipc ''"media" "playPause"''}; }
        XF86AudioNext        { ${ipc ''"media" "next"''}; }
        XF86MonBrightnessUp   { ${ipc ''"brightness" "increase"''}; }
        XF86MonBrightnessDown { ${ipc ''"brightness" "decrease"''}; }

        // screenshots
        Mod+Shift+3 { screenshot-screen; }
        Mod+Shift+4 { screenshot; }
        Mod+Shift+5 { screenshot-window; }
      }
    '';
  };
}
