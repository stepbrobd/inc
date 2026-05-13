{ inputs, lib, ... }:

{ config, pkgs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [ starship ];

  programs.carapace.enable = true;
  home.packages = [ pkgs.carapace-bridge ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    history.path = "${config.xdg.stateHome}/zsh/history";

    defaultKeymap = "viins";
    autocd = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = lib.mkMerge [
      # bat
      (lib.mkIf config.programs.bat.enable { cat = "bat --plain"; })
      # lsd
      (lib.mkIf config.programs.lsd.enable {
        # ls = "lsd";
        tree = "lsd --tree";
      })
      # must use neovim
      rec {
        nano = "nvim";
        vi = "nvim";
        vim = "nvim";
        vimdiff = "nvim -d";
        # emacs daemon like behavior but for neovim
        vims = nvims;
        nvims = "nvim --headless --listen '/tmp/nvim.'$(pwd | sha256sum | cut -c1-8)";
        # attach to a nvim "daemon"
        vimc = nvimc;
        nvimc = "nvim --remote-ui --server '/tmp/nvim.'$(pwd | sha256sum | cut -c1-8)";
        # attach to a nvim "daemon" but with neovide
        vimcv = nvimc;
        nvimcv = "neovide --server '/tmp/nvim.'$(pwd | sha256sum | cut -c1-8)";
      }
      # tailscale
      (lib.mkIf pkgs.stdenv.isDarwin {
        tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      })
      # other aliases
      { tf = "tofu"; }
    ];

    envExtra = ''
      export SHELL=$(which zsh)
    '';

    profileExtra = lib.optionalString pkgs.stdenv.isDarwin ''
      eval $(${
        if pkgs.stdenv.hostPlatform.isx86_64 then
          "/usr/local/bin"
        else if pkgs.stdenv.hostPlatform.isAarch64 then
          "/opt/homebrew/bin"
        else
          abort "Unsupported OS"
      }/brew shellenv)
    '';

    initContent = lib.mkAfter ''
      export KEYTIMEOUT=1
      export VI_MODE_SET_CURSOR=true

      _set_cursor_shape() {
        if [[ ''${KEYMAP} == 'vicmd' ]]; then
          printf '\e[2 q'
        else
          printf '\e[6 q'
        fi
      }
      zle-keymap-select() { _set_cursor_shape }
      zle-line-init() { _set_cursor_shape }
      zle -N zle-keymap-select
      zle -N zle-line-init
      precmd_functions+=(_set_cursor_shape)
    '';
  };
}
