{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    graphical
    trampoline

    # alacritty # imported in graphical
    # atuin # imported in graphical
    # bat # imported in graphical
    # btop # imported in graphical
    # direnv # imported in graphical
    # fzf # imported in graphical
    # git # imported in graphical
    # gpg # imported in graphical
    # lsd # imported in graphical
    # mpd # linux only
    # nushell # imported in graphical
    # tmux # imported in minimal
    # zoxide # imported in graphical
    # zsh # imported in minimal
  ];
}
