{ pkgs, ... }:

{
  plugins.blink-cmp = {
    enable = true;

    settings = {
      sources = {
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
          "dictionary"
        ];
        providers.dictionary = {
          name = "Dict";
          module = "blink-cmp-dictionary";
          min_keyword_length = 3;
          opts.dictionary_files = [ "${pkgs.miscfiles}/share/web2" ];
        };
      };

      keymap = {
        "<Down>" = [ "select_next" "fallback" ];
        "<Tab>" = [ "select_next" "fallback" ];
        "<C-n>" = [ "select_next" "fallback" ];
        "<C-j>" = [ "select_next" "fallback" ];

        "<Up>" = [ "select_prev" "fallback" ];
        "<C-p>" = [ "select_prev" "fallback" ];
        "<C-k>" = [ "select_prev" "fallback" ];

        "<C-d>" = [ "scroll_documentation_up" "fallback" ];
        "<C-f>" = [ "scroll_documentation_down" "fallback" ];

        "<C-Space>" = [ "show" "show_documentation" "hide_documentation" "fallback" ];
        "<S-Tab>" = [ "hide" "fallback" ];

        "<CR>" = [ "accept" "fallback" ];
      };

      snippets.preset = "luasnip";

      completion = {
        ghost_text.enabled = true;

        menu = {
          auto_show = true;
          border = "rounded";
          winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None";
        };

        documentation = {
          auto_show = true;
          auto_show_delay_ms = 250;
          window = {
            border = "rounded";
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,Search:None";
          };
        };
      };

      signature = {
        enabled = true;
        window.border = "rounded";
      };

      appearance = {
        nerd_font_variant = "mono";
        use_nvim_cmp_as_default = false;
      };
    };
  };

  plugins.blink-cmp-dictionary.enable = true;
}
