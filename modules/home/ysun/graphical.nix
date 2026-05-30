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
    # hyprland # linux only
    jujutsu
    lazygit
    llm
    lsd
    man
    # mpd # linux only
    neovide
    niks3
    # nh
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
