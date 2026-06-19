{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    packages

    nushell
    tmux
    xdg-ninja
    # zellij
    zsh
  ];
}
