{
  plugins.lsp.enable = true;
  plugins.lsp.inlayHints = true;
  plugins.lspkind.enable = true;

  plugins.conform-nvim = {
    enable = true;
    settings = {
      format_on_save.lsp_format = "fallback";
      formatters_by_ft = {
        nix = {
          __unkeyed-1 = "nixpkgs_fmt";
          __unkeyed-2 = "nixfmt";
          stop_after_first = true;
        };
        go = [ "goimports" "gofmt" ];
        ocaml = [ "ocamlformat" ];
        c = [ "clang-format" ];
        cpp = [ "clang-format" ];
        markdown = [ "deno_fmt" ];
        html = [ "deno_fmt" ];
        css = [ "deno_fmt" ];
        json = [ "deno_fmt" ];
        jsonc = [ "deno_fmt" ];
        javascript = [ "deno_fmt" ];
        javascriptreact = [ "deno_fmt" ];
        typescript = [ "deno_fmt" ];
        typescriptreact = [ "deno_fmt" ];
      };
    };
  };

  # C/C++
  plugins.lsp.servers.clangd = {
    enable = true;
    package = null;
  };

  # Coq
  plugins.lsp.servers.coq_lsp = {
    enable = true;
    package = null; # pkgs.coqPackages.coq-lsp;
  };

  # Go
  plugins.lsp.servers.gopls = {
    enable = true;
    package = null;
  };

  # HTML/JS/TS/CSS
  plugins.lsp.servers.cssls = {
    enable = true;
    package = null;
  };
  plugins.lsp.servers.denols = {
    enable = true;
    package = null;
    extraOptions.root_dir = "require('lspconfig').util.root_pattern('deno.json', 'deno.jsonc')";
  };
  plugins.lsp.servers.html = {
    enable = true;
    package = null;
  };
  plugins.lsp.servers.tailwindcss = {
    enable = true;
    package = null;
  };
  plugins.lsp.servers.ts_ls = {
    enable = true;
    package = null;
    extraOptions.root_dir = "require('lspconfig').util.root_pattern('package.json', 'tsconfig.json', 'jsconfig.json')";
  };

  # Markdown
  plugins.lsp.servers.markdown_oxide.enable = true;

  # Nix
  plugins.nix.enable = true;
  plugins.nix-develop.enable = true;
  plugins.lsp.servers.nil_ls.enable = true;
  plugins.lsp.servers.nixd = {
    enable = true;
    extraOptions.offset_encoding = "utf-8"; # nixvim#2390
  };

  # OCaml
  plugins.lsp.servers.ocamllsp = {
    enable = true;
    package = null;
  };

  # Python
  plugins.lsp.servers.ruff.enable = true;
  plugins.lsp.servers.pyright = {
    enable = true;
    package = null;
  };

  # Rust
  plugins.lsp.servers.rust_analyzer = {
    enable = true;
    package = null;
    installCargo = false;
    installRustc = false;
  };

  # Shell
  plugins.lsp.servers.bashls.enable = true;
  plugins.lsp.servers.nushell.enable = true;

  # SMT2
  plugins.lsp.servers.dolmenls = {
    enable = true;
    package = null;
  };

  # Spelling
  plugins.lsp.servers.typos_lsp = {
    enable = true;
    extraOptions.init_options.diagnosticSeverity = "Hint";
  };

  # TeX
  plugins.lsp.servers.ltex_plus = {
    enable = true;
    package = null;
  };

  # Typst
  plugins.lsp.servers.tinymist.enable = true;

  keymaps = [
    {
      mode = "n";
      key = "gd";
      action.__raw = "function() Snacks.picker.lsp_definitions() end";
      options = { silent = true; desc = "Goto definition"; };
    }
    {
      mode = "n";
      key = "gD";
      action = "<cmd>lua vim.lsp.buf.declaration()<CR>";
      options = { silent = true; desc = "Goto declaration"; };
    }
    {
      mode = "n";
      key = "gi";
      action.__raw = "function() Snacks.picker.lsp_implementations() end";
      options = { silent = true; desc = "Goto implementation"; };
    }
    {
      mode = "n";
      key = "gr";
      action.__raw = "function() Snacks.picker.lsp_references() end";
      options = { silent = true; desc = "List references"; };
    }
    {
      mode = "n";
      key = "gy";
      action.__raw = "function() Snacks.picker.lsp_type_definitions() end";
      options = { silent = true; desc = "Goto type definition"; };
    }
    {
      mode = "n";
      key = "K";
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      options = { silent = true; desc = "Hover documentation"; };
    }
    {
      mode = "n";
      key = "<leader>rn";
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      options = { silent = true; desc = "Rename symbol"; };
    }
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      options = { silent = true; desc = "Code action"; };
    }
    {
      mode = [ "i" "s" ];
      key = "<C-s>";
      action = "<cmd>lua vim.lsp.buf.signature_help()<CR>";
      options = { silent = true; desc = "Signature help"; };
    }
  ];
}
