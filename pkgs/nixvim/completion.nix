# https://github.com/MikaelFangel/nixvim-config/blob/92924c1938e48fd3b77166e616ae6e6bd4a5587b/config/cmp.nix

{
  plugins.cmp = {
    enable = true;

    settings = {
      completion.completeopt = "menu,menuone,noinsert";
      experimental.ghost_text = true;

      snippet.expand = ''
        function(args)
          require('luasnip').lsp_expand(args.body)
        end
      '';

      autoEnableSources = true;
      sources = [
        { name = "nvim_lsp"; }
        { name = "nvim_lsp_signature_help"; }
        { name = "luasnip"; }
        { name = "nvim_lsp_document_symbol"; }
        { name = "treesitter"; }
        { name = "nvim_lua"; }
        { name = "calc"; }
        { name = "dap"; }
        { name = "path"; }
        { name = "git"; }
        { name = "buffer"; }
        { name = "rg"; }
        { name = "latex_symbols"; }
        { name = "dictionary"; }
        { name = "spell"; }
        { name = "emoji"; }
      ];

      performance = {
        debounce = 50;
        fetching_timeout = 250;
        max_view_entries = 50;
      };

      formatting = {
        expandable_indicator = true;
        fields = [ "kind" "abbr" "menu" ];
      };

      window = {
        completion.__raw = ''
          cmp.config.window.bordered({
            winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
          })
        '';
        documentation.__raw = ''
          cmp.config.window.bordered({
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,Search:None",
          })
        '';
      };

      mapping = {
        "<Down>" = "cmp.mapping.select_next_item()";
        "<Tab>" = "cmp.mapping.select_next_item()";
        "<C-n>" = "cmp.mapping.select_next_item()";
        "<C-j>" = "cmp.mapping.select_next_item()";

        "<Up>" = "cmp.mapping.select_prev_item()";
        "<C-p>" = "cmp.mapping.select_prev_item()";
        "<C-k>" = "cmp.mapping.select_prev_item()";

        "<C-d>" = "cmp.mapping.scroll_docs(-4)";
        "<C-f>" = "cmp.mapping.scroll_docs(4)";

        "<C-Space>" = "cmp.mapping.complete()";
        "<S-Tab>" = "cmp.mapping.close()";
      };
    };
  };
}
