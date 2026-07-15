{ pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    tmux.enableShellIntegration = true;

    defaultCommand = "${pkgs.lib.getExe pkgs.fd} --type f --hidden --follow --exclude .git";
    changeDirWidget.command = "${pkgs.lib.getExe pkgs.fd} --type d --hidden --follow --exclude .git";
  };
}
