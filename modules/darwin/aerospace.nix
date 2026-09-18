{
  services.aerospace = {
    enable = true;

    settings = {
      gaps = {
        outer = {
          top = 4;
          bottom = 4;
          left = 4;
          right = 4;
        };
        inner = {
          horizontal = 4;
          vertical = 4;
        };
      };

      workspace-to-monitor-force-assignment = {
        "1" = "main";
        "2" = "main";
        "3" = "main";
        "4" = "main";
        "5" = "main";
        "6" = "secondary";
        "7" = "secondary";
        "8" = "secondary";
        "9" = "secondary";
        "10" = "secondary";
      };

      on-focus-changed = [ "move-mouse window-lazy-center" ];

      mode.main.binding = {
        "cmd-shift-r" = "reload-config";

        # window management
        "cmd-backslash" = "layout floating tiling";
        "cmd-leftSquareBracket" = "join-with left";
        "cmd-rightSquareBracket" = "join-with right";

        # focus
        "cmd-h" = "focus left";
        "cmd-j" = "focus down";
        "cmd-k" = "focus up";
        "cmd-l" = "focus right";

        # move window
        "cmd-ctrl-h" = "move left";
        "cmd-ctrl-j" = "move down";
        "cmd-ctrl-k" = "move up";
        "cmd-ctrl-l" = "move right";

        # focus monitor
        "cmd-shift-h" = "focus-monitor left";
        "cmd-shift-j" = "focus-monitor down";
        "cmd-shift-k" = "focus-monitor up";
        "cmd-shift-l" = "focus-monitor right";

        # move window to monitor
        "cmd-ctrl-shift-h" = "move-node-to-monitor left";
        "cmd-ctrl-shift-j" = "move-node-to-monitor down";
        "cmd-ctrl-shift-k" = "move-node-to-monitor up";
        "cmd-ctrl-shift-l" = "move-node-to-monitor right";

        # resize
        "cmd-ctrl-left" = "resize smart -50";
        "cmd-ctrl-right" = "resize smart +50";

        # workspaces
        "cmd-1" = "workspace 1";
        "cmd-2" = "workspace 2";
        "cmd-3" = "workspace 3";
        "cmd-4" = "workspace 4";
        "cmd-5" = "workspace 5";
        "cmd-6" = "workspace 6";
        "cmd-7" = "workspace 7";
        "cmd-8" = "workspace 8";
        "cmd-9" = "workspace 9";
        "cmd-0" = "workspace 10";

        "cmd-ctrl-1" = "move-node-to-workspace 1";
        "cmd-ctrl-2" = "move-node-to-workspace 2";
        "cmd-ctrl-3" = "move-node-to-workspace 3";
        "cmd-ctrl-4" = "move-node-to-workspace 4";
        "cmd-ctrl-5" = "move-node-to-workspace 5";
        "cmd-ctrl-6" = "move-node-to-workspace 6";
        "cmd-ctrl-7" = "move-node-to-workspace 7";
        "cmd-ctrl-8" = "move-node-to-workspace 8";
        "cmd-ctrl-9" = "move-node-to-workspace 9";
        "cmd-ctrl-0" = "move-node-to-workspace 10";
      };

      on-window-detected = [
        # workspace 1
        {
          "if".app-id = "org.alacritty";
          run = "move-node-to-workspace 1";
        }
        # workspace 2
        {
          "if".app-id = "com.apple.Safari";
          run = "move-node-to-workspace 2";
        }
        # workspace 8
        {
          "if".app-id = "com.apple.mail";
          run = "move-node-to-workspace 8";
        }
        # workspace 9
        {
          "if".app-id = "com.apple.iCal";
          run = "move-node-to-workspace 9";
        }
        {
          "if".app-id = "com.culturedcode.ThingsMac";
          run = "move-node-to-workspace 9";
        }
        # workspace 10
        {
          "if".app-id = "com.apple.Music";
          run = "move-node-to-workspace 10";
        }
        {
          "if".app-id = "com.automattic.beeper.desktop";
          run = "move-node-to-workspace 10";
        }
        {
          "if".app-id = "com.hnc.Discord";
          run = "move-node-to-workspace 10";
        }
        # floating
        {
          "if".app-id = "com.apple.systempreferences";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.Passwords";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.finder";
          run = "layout floating";
        }
      ];
    };
  };
}
