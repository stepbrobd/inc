{ config, ... }:

{
  programs.claude-code = {
    enable = true;

    configDir = "${config.xdg.configHome}/claude";

    context = ./context.md;

    settings = {
      theme = "dark";
      tui = "fullscreen";
      editorMode = "vim";
      verbose = true;
      effortLevel = "xhigh";
      alwaysThinkingEnabled = true;
      autoCompactWindow = 500000;
      subagentPromptCacheTtl = "1h";
      autoMemoryEnabled = false;
      agentPushNotifEnabled = true;
      remoteControlAtStartup = false;
      skipDangerousModePermissionPrompt = true;
      permissions.defaultMode = "bypassPermissions";
      enabledPlugins."superpowers@claude-plugins-official" = true;

      attribution = {
        commit = "";
        pr = "";
        sessionUrl = false;
      };
    };

    lspServers = {
      bashls = {
        command = "bash-language-server";
        args = [ "start" ];
        extensionToLanguage = {
          ".bash" = "shellscript";
          ".sh" = "shellscript";
        };
      };
      clangd = {
        command = "clangd";
        args = [ "--background-index" ];
        extensionToLanguage = {
          ".c" = "c";
          ".h" = "c";
          ".cc" = "cpp";
          ".cpp" = "cpp";
          ".cxx" = "cpp";
          ".hpp" = "cpp";
          ".hxx" = "cpp";
        };
      };
      coq-lsp = {
        command = "coq-lsp";
        extensionToLanguage.".v" = "rocq";
      };
      denols = {
        command = "deno";
        args = [ "lsp" ];
        extensionToLanguage = {
          ".cjs" = "javascript";
          ".cts" = "typescript";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
          ".mjs" = "javascript";
          ".mts" = "typescript";
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
        };
      };
      dolmenls = {
        command = "dolmenls";
        extensionToLanguage.".smt2" = "smt2";
      };
      fsautocomplete = {
        command = "fsautocomplete";
        extensionToLanguage = {
          ".fs" = "fsharp";
          ".fsi" = "fsharp";
          ".fsx" = "fsharp";
        };
      };
      gopls = {
        command = "gopls";
        extensionToLanguage.".go" = "go";
      };
      nixd = {
        command = "nixd";
        args = [ "--log=error" ];
        extensionToLanguage.".nix" = "nix";
      };
      nushell = {
        command = "nu";
        args = [ "--lsp" ];
        extensionToLanguage.".nu" = "nu";
      };
      ocamllsp = {
        command = "ocamllsp";
        extensionToLanguage = {
          ".ml" = "ocaml";
          ".mli" = "ocaml";
        };
      };
      pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      rust-analyzer = {
        command = "rust-analyzer";
        extensionToLanguage.".rs" = "rust";
      };
      sourcekit-lsp = {
        command = "sourcekit-lsp";
        extensionToLanguage.".swift" = "swift";
      };
      taplo = {
        command = "taplo";
        args = [ "lsp" "stdio" ];
        extensionToLanguage.".toml" = "toml";
      };
      tinymist = {
        command = "tinymist";
        extensionToLanguage.".typ" = "typst";
      };
    };
  };
}
