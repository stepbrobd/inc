{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    packages

    go
    hushlogin
    nushell
    tmux
    xdg
    # zellij
    zsh
  ];
}
