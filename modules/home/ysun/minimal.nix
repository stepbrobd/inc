{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    nushell
    tmux
    xdg-ninja
    # zellij
    zsh
  ];
}
