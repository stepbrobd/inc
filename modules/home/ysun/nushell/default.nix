{ inputs, lib, ... }:

{ config, pkgs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [ starship ];

  programs.carapace.enable = true;
  home.packages = [ pkgs.carapace-bridge ];

  programs.dircolors.enable = true;

  # weird ass nushell uses `~/Library/Application Support/nushell` on darwin unless XDG_CONFIG_HOME is set
  home.file."Library/Application Support/nushell" = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.xdg.enable) {
    source = config.lib.file.mkOutOfStoreSymlink config.programs.nushell.configDir;
  };

  programs.nushell = {
    enable = true;
    loadSessionVariables = true;

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
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      })
      # other aliases
      { tf = "tofu"; }
    ];

    configFile.text = /* nu */ ''
      $env.config = {
        show_banner: false
        highlight_resolved_externals: true

        edit_mode: vi
        cursor_shape: {
          vi_insert: line
          vi_normal: block
        }

        completions: {
          algorithm: fuzzy
        }

        history: {
          file_format: sqlite
        }


        filesize: {
          unit: binary
        }

        datetime_format: {
          normal: "%Y-%m-%d %H:%M:%S"
          table: "%Y-%m-%d %H:%M:%S"
        }

        table: {
          mode: markdown
          index_mode: auto
          missing_value_symbol: ""
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
      $env.CARAPACE_MATCH = "CASE_INSENSITIVE"
    '';
  };
}
