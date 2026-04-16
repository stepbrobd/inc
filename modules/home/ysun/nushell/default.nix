{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  # this is for hijacking zsh and bash to launch nushell
  # without implementing envvar logic in home-manager
  initExtra = ''
    if [[ $- == *i* && -z "$__NU_LAUNCHED" ]] && command -v nu > /dev/null; then
        export __NU_LAUNCHED=1
        LOGIN_OPT=""
        if [ -n "$BASH_VERSION" ] && shopt -q login_shell; then
            LOGIN_OPT="--login"
        elif [ -n "$ZSH_VERSION" ] && [[ -o login ]]; then
            LOGIN_OPT="--login"
        fi
        exec nu $LOGIN_OPT
    fi
  '';
in
{
  programs.zsh.initContent = lib.mkOrder 9999 initExtra;
  programs.bash = { inherit initExtra; };

  imports = with inputs.self.homeManagerModules.ysun; [ starship ];

  programs.carapace.enable = true;
  home.packages = [ pkgs.carapace-bridge ];

  programs.nushell = {
    enable = true;

    shellAliases = lib.mkMerge [
      # bat
      (lib.mkIf config.programs.bat.enable { cat = "bat --plain"; })
      # lsd
      (lib.mkIf config.programs.lsd.enable {
        # ls = "lsd"; # use nushell builtin ls
        tree = "lsd --tree";
      })
      # must use neovim
      rec {
        nano = "nvim";
        vi = "nvim";
        vim = "nvim";
        vimdiff = "nvim -d";
        # NOTE: also in zsh user module
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

    configFile.text = /* nu */ ''
      $env.config = {
        edit_mode: vi
        show_banner: false
        cursor_shape: {
          vi_insert: line
          vi_normal: block
        }
        menus: [
          {
            name: help_menu
            only_buffer_difference: true # Search is done on the text written after activating the menu
            marker: ""                   # Indicator that appears with the menu is active
            type: {
                layout: description      # Type of menu
                columns: 4               # Number of columns where the options are displayed
                col_width: 20            # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2           # Padding between columns
                selection_rows: 4        # Number of rows allowed to display found options
                description_rows: 10     # Number of rows allowed to display command description
            }
            style: {
                text: green                   # Text style
                selected_text: green_reverse  # Text style for selected option
                description_text: yellow      # Text style for description
            }
          }
          {
            name: completion_menu
            only_buffer_difference: false # Search is done on the text written after activating the menu
            marker: ""                    # Indicator that appears with the menu is active
            type: {
                layout: columnar          # Type of menu
                columns: 4                # Number of columns where the options are displayed
                col_width: 20             # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2            # Padding between columns
            }
            style: {
                text: green                   # Text style
                selected_text: green_reverse  # Text style for selected option
                description_text: yellow      # Text style for description
            }
          }
          {
            name: history_menu
            only_buffer_difference: true # Search is done on the text written after activating the menu
            marker: ""                   # Indicator that appears with the menu is active
            type: {
                layout: list             # Type of menu
                page_size: 10            # Number of entries that will presented when activating the menu
            }
            style: {
                text: green                   # Text style
                selected_text: green_reverse  # Text style for selected option
                description_text: yellow      # Text style for description
            }
          }
        ]
      }
    '';

    extraEnv = ''
      $env.SHELL = (which nu | get path.0)
      $env.PROMPT_COMMAND = ""
      $env.PROMPT_COMMAND_RIGHT = ""
      $env.PROMPT_INDICATOR = ""
      $env.PROMPT_INDICATOR_VI_INSERT = ""
      $env.PROMPT_INDICATOR_VI_NORMAL = ""
      $env.PROMPT_MULTILINE_INDICATOR = ""
    '';

    extraConfig = lib.mkAfter (
      lib.concatStringsSep "\n" [
        "const NU_LIB_DIRS = $NU_LIB_DIRS ++ ['${pkgs.nu_scripts}/share/nu_scripts']"
        "use themes/nu-themes/nord.nu"
      ]
    );
  };
}
