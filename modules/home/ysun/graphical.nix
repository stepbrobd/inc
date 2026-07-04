{ inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [
    minimal
    nix

    alacritty
    ani
    atuin
    bat
    btop
    # chromium # linux only
    email
    direnv
    # firefox # linux only
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
    # mpd # linux only
    neovide
    neovim
    niks3
    # nushell # imported in minimal
    openconnect
    openvpn
    ripgrep
    ssh
    # tmux # imported in minimal
    vscode
    yazi
    zoxide
    # zsh # imported in minimal
  ];
}
