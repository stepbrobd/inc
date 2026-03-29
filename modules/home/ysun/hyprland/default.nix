{ inputs, ... }:

{ pkgs
, config
, osConfig ? { services.desktopManager.enabled = null; }
, ...
}:

{
  imports = [ inputs.self.homeManagerModules.ysun.noctalia ];

  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;

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

  home.packages = with pkgs; [
    brightnessctl
    cliphist
    ddcutil
    gnome-keyring
    grimblast
    hyprmon
    networkmanagerapplet
    wl-clipboard
    wireplumber
  ];

  wayland.windowManager.hyprland = {
    enable = osConfig.services.desktopManager.enabled == "hyprland";
    xwayland.enable = true;

    extraConfig = ''
      monitor = eDP-1, highres, 0x0, 1.5, bitdepth, 8, cm, srgb, vrr, 1
      monitor = , preferred, auto, auto, bitdepth, 8, cm, srgb

      env = GDK_SCALE,1
      env = ELM_SCALE,1
      env = QT_SCALE_FACTOR,1
      env = XCURSOR_SIZE,24
      xwayland {
        force_zero_scaling = true
      }

      render {
        direct_scanout = 2
      }

      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = nm-applet --indicator &
      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
      exec-once = gnome-keyring-daemon --start --components=pkcs11,secrets,ssh &

      exec-once = noctalia-shell &
      exec-once = fcitx5 -d

      ecosystem {
        no_update_news = true
        no_donation_nag = true
      }

      general {
        gaps_in = 4
        gaps_out = 4
        border_size = 2
        col.active_border=0xff4c566a
        col.inactive_border=0xff2e3440
        layout = dwindle
      }

      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =
          sensitivity = 0
          follow_mouse = 1
          natural_scroll = true
          scroll_method = 2fg
          touchpad {
              natural_scroll = true
          }
      }

      gesture = 4, vertical, workspace

      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
        mouse_move_enables_dpms = true
        enable_swallow = true
      }

      decoration {
        rounding = 8
        active_opacity = 1.0
        inactive_opacity = 1.0
        blur {
          enabled = true
          size = 3
          passes = 2
          vibrancy = 0.1696
        }
        shadow {
          enabled = false
        }
      }

      layerrule {
        name = noctalia
        match:namespace = noctalia-background-.*$
        ignore_alpha = 0.5
        blur = true
        blur_popups = true
      }

      animations {
        enabled = true

        bezier = overshot, 0.05, 0.9, 0.1, 1.05
        bezier = smoothOut, 0.36, 0, 0.66, -0.56
        bezier = smoothIn, 0.25, 1, 0.5, 1

        animation = windows, 1, 5, overshot, slide
        animation = windowsOut, 1, 4, smoothOut, slide
        animation = windowsMove, 1, 4, default
        animation = border, 1, 10, default
        animation = fade, 1, 10, smoothIn
        animation = fadeDim, 1, 10, smoothIn
        animation = workspaces, 1, 6, overshot, slidevert
      }

      dwindle {
        pseudotile = true
        preserve_split = true
      }

      $ipc = noctalia-shell ipc call

      bind = CTRL SUPER, Q, exec, $ipc lockScreen lock
      bindl = , XF86AudioMute, exec, $ipc volume muteOutput
      bindel = , XF86AudioRaiseVolume, exec, $ipc volume increase
      bindel = , XF86AudioLowerVolume, exec, $ipc volume decrease
      bindl = , XF86AudioPrev, exec, $ipc media previous
      bindl = , XF86AudioPlay, exec, $ipc media playPause
      bindl = , XF86AudioNext, exec, $ipc media next
      bindel = , XF86MonBrightnessUp, exec, $ipc brightness increase
      bindel = , XF86MonBrightnessDown, exec, $ipc brightness decrease
      bind = SUPER SHIFT, 3, exec, grimblast save screen
      bind = SUPER SHIFT, 4, exec, grimblast save active
      bind = SUPER SHIFT, 5, exec, grimblast save area

      $mod = SUPER

      bind = $mod, T, exec, alacritty
      bind = $mod, S, exec, $ipc volume togglePanel
      bind = $mod, SPACE, exec, $ipc launcher toggle

      bind = $mod, M, exec, $ipc sessionMenu toggle
      bind = $mod, Q, killactive,
      bind = $mod, F, fullscreen,
      bind = $mod, A, pseudo,
      bind = $mod, X, togglesplit,
      bind = $mod, Z, togglefloating,

      bind = $mod, H, movefocus, l
      bind = $mod, L, movefocus, r
      bind = $mod, K, movefocus, u
      bind = $mod, J, movefocus, d

      bind = $mod, left, movecurrentworkspacetomonitor, l
      bind = $mod, right, movecurrentworkspacetomonitor, r

      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10

      bindm = $mod CTRL, mouse:272, movewindow
      bindm = $mod CTRL, mouse:273, resizewindow

      bind = $mod CTRL, H, movewindow, l
      bind = $mod CTRL, L, movewindow, r
      bind = $mod CTRL, K, movewindow, u
      bind = $mod CTRL, J, movewindow, d

      bind = $mod CTRL, left, resizeactive, -20 0
      bind = $mod CTRL, right, resizeactive, 20 0
      bind = $mod CTRL, up, resizeactive, 0 -20
      bind = $mod CTRL, down, resizeactive, 0 20

      bind = $mod CTRL, 1, movetoworkspace, 1
      bind = $mod CTRL, 2, movetoworkspace, 2
      bind = $mod CTRL, 3, movetoworkspace, 3
      bind = $mod CTRL, 4, movetoworkspace, 4
      bind = $mod CTRL, 5, movetoworkspace, 5
      bind = $mod CTRL, 6, movetoworkspace, 6
      bind = $mod CTRL, 7, movetoworkspace, 7
      bind = $mod CTRL, 8, movetoworkspace, 8
      bind = $mod CTRL, 9, movetoworkspace, 9
      bind = $mod CTRL, 0, movetoworkspace, 10
    '';
  };
}
