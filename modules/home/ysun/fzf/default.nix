{ pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    tmux.enableShellIntegration = true;

    defaultCommand = "${pkgs.lib.getExe pkgs.fd} --type f --hidden --follow --exclude .git";
    changeDirWidget.command = "${pkgs.lib.getExe pkgs.fd} --type d --hidden --follow --exclude .git";

    colors = {
      fg = "#e5e9f0";
      "fg+" = "#e5e9f0";
      bg = "#3b4252";
      "bg+" = "#3b4252";
      hl = "#81a1c1";
      "hl+" = "#81a1c1";
      info = "#eacb8a";
      prompt = "#bf6069";
      pointer = "#b48dac";
      marker = "#a3be8b";
      spinner = "#b48dac";
      header = "#a3be8b";
    };
  };
}
