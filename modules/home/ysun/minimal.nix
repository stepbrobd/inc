{ inputs, ... }:

{
  home.stateVersion = "25.05";

  imports = with inputs.self.homeManagerModules.ysun; [
    stylix

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
