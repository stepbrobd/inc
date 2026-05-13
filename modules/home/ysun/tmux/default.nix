{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    keyMode = "vi";
    mouse = true;
    clock24 = true;
    terminal = "screen-256color";

    plugins = with pkgs.tmuxPlugins; [
      nord
      continuum
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-dir "${config.xdg.dataHome}/tmux/resurrect"
        '';
      }
    ];
    sensibleOnTop = false;

    extraConfig = ''
      # tmux-sensible
      set -s escape-time 0
      set -g history-limit 99999
      set -g display-time 2500
      set -g status-interval 5
      set -g status-keys emacs
      set -g focus-events on
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      setw -g aggressive-resize on
      bind C-p previous-window
      bind C-n next-window
      set -g default-command "$SHELL"

      set -g status on
      set -g status-position top

      set -g base-index 1
      setw -g pane-base-index 1

      set -g allow-rename on
      setw -g automatic-rename
      set-option -g renumber-windows on

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # fast reload
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux: config reloaded"
      bind s set-window-option synchronize-panes\; display-message "synchronize-panes: #{?pane_synchronized,on,off}"

      # start session index from 1
      set-option -g @first-run 1
      set-hook -g session-created {
        if-shell -F '#{?@first-run,1,0}' {
          set-option -g @first-run 0
          if-shell -F '#{==:#{session_name},0}' { rename-session 1 }
        }
      }
    '' + pkgs.lib.optionalString config.programs.alacritty.enable ''
      set -g default-terminal "alacritty"
      set-option -ga terminal-overrides ",alacritty:Tc"
    '';
  };
}
