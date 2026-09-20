{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    minimal
    nix

    alacritty
    bat
    btop
    email
    direnv
    fd
    fzf
    gh
    git
    gpg
    jq
    jujutsu
    lazygit
    llm
    lsd
    man
    media
    miroir
    # mpd # linux only
    neovide
    neovim
    niks3
    # nushell # imported in minimal
    openconnect
    openvpn
    ripgrep
    ssh
    things
    # tmux # imported in minimal
    yazi
    zoxide
    # zsh # imported in minimal
  ];
}
