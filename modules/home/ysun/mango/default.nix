{ lib, inputs, ... }:

{ config
, pkgs
, osConfig ? { networking.hostName = ""; }
, ...
}:

let
  hasTag = lib.hasTag osConfig.networking.hostName;

  ipc = args: "spawn,noctalia msg ${args}";

  screenshot = "$HOME/Pictures/Screenshots/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png";
in
{
  imports = [ inputs.mango.hmModules.mango ];

  config = lib.mkIf (hasTag "mango") {
    home.packages = with pkgs; [
      gnome-keyring
      grim
      mangomon
      slurp
    ];

    wayland.windowManager.mango = {
      enable = true;

      systemd.enable = pkgs.stdenv.hostPlatform.isLinux;

      settings = {
        # input
        xkb_rules_layout = "us";
        tap_to_click = 1;
        tap_and_drag = 1;
        trackpad_natural_scrolling = 1;
        trackpad_scroll_method = 1; # two-finger
        trackpad_click_method = 2; # clickfinger
        trackpad_disable_while_typing = 1;
        mouse_natural_scrolling = 1;
        sloppyfocus = 1;
        warpcursor = 1;

        # look
        borderpx = 2;
        border_radius = 8;
        gappih = 4;
        gappiv = 4;
        gappoh = 4;
        gappov = 4;
        focuscolor = "0x${config.lib.stylix.colors.base03}ff";
        bordercolor = "0x${config.lib.stylix.colors.base00}ff";
        rootcolor = "0x${config.lib.stylix.colors.base00}ff";
        dropcolor = "0x${config.lib.stylix.colors.base0D}80";
        urgentcolor = "0x${config.lib.stylix.colors.base08}ff";
        splitcolor = "0x${config.lib.stylix.colors.base09}ff";
        maximizescreencolor = "0x${config.lib.stylix.colors.base0B}ff";
        scratchpadcolor = "0x${config.lib.stylix.colors.base0F}ff";
        globalcolor = "0x${config.lib.stylix.colors.base0E}ff";
        overlaycolor = "0x${config.lib.stylix.colors.base0C}ff";
        cursor_theme = config.stylix.cursor.name;
        cursor_size = config.stylix.cursor.size;

        monitorrule = [ "name:eDP-1,scale:1.5" ];
        # don't scale xwayland in global to avoid blurry
        xwayland_ignore_scale = 1;

        # layout
        tagrule = [ "id:*,layout_name:scroller" ];
        circle_layout = lib.concatStringsSep "," [
          "scroller"
          "vertical_scroller"

          "dwindle"

          "tile"
          "center_tile"

          "fair"
          "vertical_fair"

          # "deck"
          # "grid"
          # "monocle"
          # "right_tile"
          # "vertical_deck"
          # "vertical_grid"
          # "vertical_tile"
        ];
        scroller_default_proportion = 0.95;
        scroller_ignore_proportion_single = 0; # a single window should fills the screen
        scroller_proportion_preset = lib.concatStringsSep "," [ "0.25" "0.33" "0.50" "0.67" "0.75" "0.95" "1.00" ];
        scroller_structs = 4;
        edge_scroller_pointer_focus = 0;
        tag_animation_direction = 0; # 0 = vertical (matches 3-finger up/down)

        env = [
          "GDK_SCALE,1"
          "ELM_SCALE,1"
          "QT_SCALE_FACTOR,1"
          "XCURSOR_SIZE,${toString config.stylix.cursor.size}"
        ];

        bind = [
          # terminal
          "SUPER,t,spawn,alacritty"

          # overview
          "SUPER,o,toggleoverview"

          # thumbnail switcher
          "SUPER,Tab,switcher,all_next"
          "SUPER+SHIFT,Tab,switcher,all_prev"

          # noctalia shell IPC
          "SUPER,s,${ipc "panel-toggle control-center audio"}"
          "SUPER,space,${ipc "panel-toggle launcher"}"
          "SUPER,m,${ipc "panel-toggle session"}"
          "CTRL+SUPER,q,${ipc "session lock"}"

          # window management
          "SUPER,q,killclient"
          "SUPER,f,togglefullscreen"
          "SUPER,backslash,togglefloating"
          "SUPER,a,centerwin"
          "SUPER,bracketleft,scroller_stack,left"
          "SUPER,bracketright,scroller_stack,right"
          "SUPER,e,switch_layout"
          "SUPER+SHIFT,r,reload_config"

          # focus
          "SUPER,h,focusdir,left"
          "SUPER,l,focusdir,right"
          "SUPER,k,focus_window_or_workspace,up"
          "SUPER,j,focus_window_or_workspace,down"

          # move window
          "SUPER+CTRL,h,exchange_client,left"
          "SUPER+CTRL,l,exchange_client,right"
          "SUPER+CTRL,k,exchange_client,up"
          "SUPER+CTRL,j,exchange_client,down"

          # focus monitor
          "SUPER+SHIFT,h,focusmon,left"
          "SUPER+SHIFT,l,focusmon,right"
          "SUPER+SHIFT,k,focusmon,up"
          "SUPER+SHIFT,j,focusmon,down"

          # move window to monitor
          "SUPER+CTRL+SHIFT,h,tagmon,left"
          "SUPER+CTRL+SHIFT,l,tagmon,right"
          "SUPER+CTRL+SHIFT,k,tagmon,up"
          "SUPER+CTRL+SHIFT,j,tagmon,down"

          # tags
          "SUPER,1,view,1"
          "SUPER,2,view,2"
          "SUPER,3,view,3"
          "SUPER,4,view,4"
          "SUPER,5,view,5"
          "SUPER,6,view,6"
          "SUPER,7,view,7"
          "SUPER,8,view,8"
          "SUPER,9,view,9"

          "SUPER+CTRL,1,tag,1"
          "SUPER+CTRL,2,tag,2"
          "SUPER+CTRL,3,tag,3"
          "SUPER+CTRL,4,tag,4"
          "SUPER+CTRL,5,tag,5"
          "SUPER+CTRL,6,tag,6"
          "SUPER+CTRL,7,tag,7"
          "SUPER+CTRL,8,tag,8"
          "SUPER+CTRL,9,tag,9"

          # media keys via noctalia IPC
          "NONE,XF86AudioMute,${ipc "volume-mute"}"
          "NONE,XF86AudioRaiseVolume,${ipc "volume-up"}"
          "NONE,XF86AudioLowerVolume,${ipc "volume-down"}"
          "NONE,XF86AudioPrev,${ipc "media previous"}"
          "NONE,XF86AudioPlay,${ipc "media toggle"}"
          "NONE,XF86AudioNext,${ipc "media next"}"
          "NONE,XF86MonBrightnessUp,${ipc "brightness-up"}"
          "NONE,XF86MonBrightnessDown,${ipc "brightness-down"}"

          # screenshots (5 = area select, mango has no window capture)
          ''SUPER+SHIFT,3,spawn_shell,grim "${screenshot}"''
          ''SUPER+SHIFT,4,spawn_shell,slurp | grim -g - "${screenshot}"''
          ''SUPER+SHIFT,5,spawn_shell,slurp | grim -g - "${screenshot}"''
        ];

        # resize
        bindc = [
          "SUPER+CTRL,Left,setmfact,-0.05"
          "SUPER+CTRL,Right,setmfact,+0.05"

          "SUPER+CTRL,Left,switch_proportion_preset,prev"
          "SUPER+CTRL,Right,switch_proportion_preset,next"

          "SUPER+CTRL,Up,switch_proportion_preset,prev"
          "SUPER+CTRL,Down,switch_proportion_preset,next"
        ];

        # drag to move/resize floating windows
        # dragging a tiled window swaps it
        mousebind = [
          "SUPER,btn_left,moveresize,curmove"
          "SUPER,btn_right,moveresize,curresize"
        ];

        gesturebind = [
          # 3 finger horizontal
          "none,left,3,focusdir,right"
          "none,right,3,focusdir,left"
          # 3 finger vertical
          "none,up,3,viewtoright"
          "none,down,3,viewtoleft"
          # 4 finger up
          "none,up,4,toggleoverview"
        ];

        # lid event toggle internal monitor
        switchbind = [
          "fold,sleep_monitor,eDP-1"
          "unfold,wakeup_monitor,eDP-1"
        ];
      };

      autostart_sh = ''
        ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
        gnome-keyring-daemon --start --components=pkcs11,secrets,ssh
        noctalia &
        fcitx5 -d
      '';
    };
  };
}
