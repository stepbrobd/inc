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
    # firefox # linux only
    floorp # linux only
    # fzf # imported in graphical
    # git # imported in graphical
    # gpg # imported in graphical
    hyprland # linux only
    niri # linux only
    noctalia # linux only
    # lsd # imported in graphical
    mpd # linux only
    # nushell # imported in graphical
    orion
    # tmux # imported in minimal
    # vscode # imported in graphical
    # zathura # imported in graphical
    zen
    # zoxide # imported in graphical
    # zsh # imported in minimal
  ];
}
