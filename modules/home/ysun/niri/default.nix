{ lib, ... }:

{ config
, pkgs
, osConfig ? { networking.hostName = ""; }
, ...
}:

let
  hasTag = lib.hasTag osConfig.networking.hostName;

  ipc = args: ''spawn "noctalia" "msg" ${args}'';
in
{
  config = lib.mkIf (hasTag "niri") {
    home.packages = with pkgs; [
      gnome-keyring
      nirimon
    ];

    xdg.configFile."niri/config.kdl".text = /* kdl */ ''
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
      }

      layout {
        gaps 4
        default-column-width { proportion 0.95; }

        border {
          on
          width 2
          active-color "${config.lib.stylix.colors.withHashtag.base03}"
          inactive-color "${config.lib.stylix.colors.withHashtag.base00}"
        }

        focus-ring {
          off
        }
      }

      layer-rule {
        match namespace=r#"^noctalia-overview*"#
        place-within-backdrop true
      }

      window-rule {
        default-column-width { proportion 0.95; }
        geometry-corner-radius 8 8 8 8
        clip-to-geometry true
        open-fullscreen false
        open-maximized false
        open-maximized-to-edges false
      }

      prefer-no-csd

      gestures { hot-corners { off; }; }

      hotkey-overlay {
        skip-at-startup
      }

      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      cursor {
        xcursor-theme "${config.stylix.cursor.name}"
        xcursor-size ${toString config.stylix.cursor.size}
      }

      environment {
        GDK_SCALE "1"
        ELM_SCALE "1"
        QT_SCALE_FACTOR "1"
        XCURSOR_SIZE "${toString config.stylix.cursor.size}"
      }

      spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
      spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      spawn-at-startup "gnome-keyring-daemon" "--start" "--components=pkcs11,secrets,ssh"
      spawn-at-startup "noctalia"
      spawn-at-startup "fcitx5" "-d"

      binds {
        // terminal
        Mod+T { spawn "alacritty"; }

        // overview
        Mod+O { toggle-overview; }

        // noctalia shell IPC
        Mod+S        { ${ipc ''"panel-toggle" "control-center" "audio"''}; }
        Mod+Space    { ${ipc ''"panel-toggle" "launcher"''}; }
        Mod+M        { ${ipc ''"panel-toggle" "session"''}; }
        Ctrl+Super+Q { ${ipc ''"session" "lock"''}; }

        // window management
        Mod+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+Backslash { toggle-window-floating; }
        Mod+A { center-column; }
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }

        // focus
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-or-workspace-up; }
        Mod+J { focus-window-or-workspace-down; }

        // move window
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+K { move-window-up-or-to-workspace-up; }
        Mod+Ctrl+J { move-window-down-or-to-workspace-down; }

        // focus monitor
        Mod+Shift+H { focus-monitor-left; }
        Mod+Shift+L { focus-monitor-right; }
        Mod+Shift+K { focus-monitor-up; }
        Mod+Shift+J { focus-monitor-down; }

        // move window to monitor
        Mod+Ctrl+Shift+H { move-window-to-monitor-left; }
        Mod+Ctrl+Shift+L { move-window-to-monitor-right; }
        Mod+Ctrl+Shift+K { move-window-to-monitor-up; }
        Mod+Ctrl+Shift+J { move-window-to-monitor-down; }

        // move workspace to monitor
        Mod+Left  { move-workspace-to-monitor-left; }
        Mod+Right { move-workspace-to-monitor-right; }
        Mod+Up    { move-workspace-to-monitor-up; }
        Mod+Down  { move-workspace-to-monitor-down; }

        // resize column width / window height
        Mod+Ctrl+Left  { set-column-width "-5%"; }
        Mod+Ctrl+Right { set-column-width "+5%"; }
        Mod+Ctrl+Up    { set-window-height "-5%"; }
        Mod+Ctrl+Down  { set-window-height "+5%"; }

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

        // media keys via noctalia IPC
        XF86AudioMute         { ${ipc ''"volume-mute"''}; }
        XF86AudioRaiseVolume  { ${ipc ''"volume-up"''}; }
        XF86AudioLowerVolume  { ${ipc ''"volume-down"''}; }
        XF86AudioPrev         { ${ipc ''"media" "previous"''}; }
        XF86AudioPlay         { ${ipc ''"media" "toggle"''}; }
        XF86AudioNext         { ${ipc ''"media" "next"''}; }
        XF86MonBrightnessUp   { ${ipc ''"brightness-up"''}; }
        XF86MonBrightnessDown { ${ipc ''"brightness-down"''}; }

        // screenshots
        Mod+Shift+3 { screenshot-screen; }
        Mod+Shift+4 { screenshot; }
        Mod+Shift+5 { screenshot-window; }
      }
    '';
  };
}
