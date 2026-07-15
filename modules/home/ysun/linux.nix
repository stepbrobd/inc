{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    graphical

    # alacritty # imported in graphical
    # atuin # imported in graphical
    # bat # imported in graphical
    # btop # imported in graphical
    chromium # linux only
    # direnv # imported in graphical
    discord
    # firefox # linux only
    # fzf # imported in graphical
    # git # imported in graphical
    # gpg # imported in graphical
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
