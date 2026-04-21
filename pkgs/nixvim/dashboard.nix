{
  plugins.alpha = {
    enable = true;
    settings.layout = [
      {
        type = "padding";
        val = 10;
      }
      {
        type = "text";
        val = "not";
        opts = {
          position = "center";
          hl = "Type";
        };
      }
      {
        type = "padding";
        val = 1;
      }
      {
        type = "text";
        val = [
          "███████╗███╗   ███╗ █████╗  ██████╗███████╗"
          "██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝"
          "█████╗  ██╔████╔██║███████║██║     ███████╗"
          "██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║"
          "███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║"
          "╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝"
        ];
        opts = {
          position = "center";
          hl = "Type";
        };
      }
      {
        type = "padding";
        val = 5;
      }
      {
        type = "group";
        opts.position = "center";
        val = [
          {
            type = "button";
            val = "      New File ";
            on_press.__raw = "function() vim.cmd[[ene | startinsert]] end";
            opts = {
              position = "center";
              shortcut = "n";
              keymap = [ "n" "n" "<cmd>ene | startinsert<cr>" { noremap = true; silent = true; nowait = true; } ];
            };
          }
          {
            type = "button";
            val = "      Find File";
            on_press.__raw = "function() vim.cmd[[Telescope find_files]] end";
            opts = {
              position = "center";
              shortcut = "f";
              keymap = [ "n" "f" "<cmd>Telescope find_files<cr>" { noremap = true; silent = true; nowait = true; } ];
            };
          }
          {
            type = "button";
            val = "      Live Grep";
            on_press.__raw = "function() vim.cmd[[Telescope live_grep]] end";
            opts = {
              position = "center";
              shortcut = "g";
              keymap = [ "n" "g" "<cmd>Telescope live_grep<cr>" { noremap = true; silent = true; nowait = true; } ];
            };
          }
          {
            type = "button";
            val = "      Quit     ";
            on_press.__raw = "function() vim.cmd[[qa]] end";
            opts = {
              position = "center";
              shortcut = "q";
              keymap = [ "n" "q" "<cmd>qa<cr>" { noremap = true; silent = true; nowait = true; } ];
            };
          }
        ];
      }
      {
        type = "padding";
        val = 5;
      }
      {
        type = "text";
        val = "its neovim";
        opts = {
          position = "center";
          hl = "Type";
        };
      }
    ];
  };
}
