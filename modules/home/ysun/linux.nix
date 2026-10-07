{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    graphical

    # alacritty # imported in graphical
    # bat # imported in graphical
    # btop # imported in graphical
    # direnv # imported in graphical
    # fzf # imported in graphical
    # git # imported in graphical
    # gpg # imported in graphical
    libreoffice
    mango # linux only
    nemo
    niri # linux only
    noctalia # linux only
    # lsd # imported in graphical
    mpd # linux only
    # nushell # imported in graphical
    # tmux # imported in minimal
    slack
    zathura
    zen
    # zoxide # imported in graphical
    # zsh # imported in minimal
  ];
}
