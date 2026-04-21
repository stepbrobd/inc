{
  colorschemes.nord = {
    enable = true;
    settings = {
      borders = true;
      cursorline_transparent = false;
    };
  };

  extraConfigLuaPost = ''
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "nord",
      callback = function()
        vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "#3b4252", fg = "#d8dee9" })
        vim.api.nvim_set_hl(0, "FloatBorder",  { bg = "NONE",    fg = "#81a1c1" })
        vim.api.nvim_set_hl(0, "FloatTitle",   { bg = "NONE",    fg = "#88c0d0", bold = true })
        vim.api.nvim_set_hl(0, "WinSeparator", { bg = "NONE",    fg = "#4c566a" })
        vim.api.nvim_set_hl(0, "VertSplit",    { bg = "NONE",    fg = "#4c566a" })
      end,
    })
    vim.cmd.doautocmd { "ColorScheme", "nord" }
  '';
}
