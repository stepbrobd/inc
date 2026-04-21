{
  plugins.lualine = {
    enable = true;

    settings = {
      options = {
        theme = "nord";
        icons_enabled = true;
        disabled_filetypes.statusline = [ "snacks_dashboard" "NvimTree" ];
      };

      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [ "branch" ];
        lualine_c = [ "diff" "diagnostics" ];
        lualine_x = [ "filetype" "encoding" ];
        lualine_y = [ "progress" ];
        lualine_z = [ "location" ];
      };
    };
  };
}
