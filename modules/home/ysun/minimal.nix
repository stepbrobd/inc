{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    packages

    hushlogin
    nushell
    tmux
    xdg-ninja
    # zellij
    zsh
  ];
}
