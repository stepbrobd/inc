{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    plugins = with pkgs.yaziPlugins; {
      inherit full-border git nord yatline;
    };

    # pkgs.yaziPlugins.git
    settings.plugin.prepend_fetchers = [
      { id = "git"; name = "*"; run = "git"; }
      { id = "git"; name = "*/"; run = "git"; }
    ];

    initLua = /* lua */ ''
      -- pkgs.yaziPlugins.full-border
      require("full-border"):setup()

      -- pkgs.yaziPlugins.git
      require("git"):setup()

      -- pkgs.yaziPlugins.yatline
      require("yatline"):setup({
        -- pkgs.yaziPlugins.nord
        theme = require("nord"):setup(),

        header_line = {
          left = {
            section_a = {
              { type = "line", custom = false, name = "tabs", params = { "left" }, },
            },
            section_b = { },
            section_c = { },
          },
          right = {
            section_a = { },
            section_b = { },
            section_c = {
              { type = "coloreds", custom = false, name = "count", params = "true" },
            },
          }
        },

        status_line = {
          left = {
            section_a = {
              { type = "string", custom = false, name = "tab_mode", },
            },
            section_b = {
              { type = "string", custom = false, name = "hovered_size", },
            },
            section_c = {
              { type = "string", custom = false, name = "hovered_path", },
              { type = "coloreds", custom = false, name = "count", },
            },
          },
          right = {
            section_a = {
              { type = "string", custom = false, name = "cursor_position", },
            },
            section_b = {
              { type = "string", custom = false, name = "cursor_percentage", },
            },
            section_c = {
              { type = "string", custom = false, name = "hovered_file_extension", params = { true }, },
              { type = "coloreds", custom = false, name = "permissions", },
            },
          },
        },
      })
    '';
  };
}
