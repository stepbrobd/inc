{
  viAlias = false;
  vimAlias = false;
  wrapRc = true;

  withNodeJs = false;
  withPerl = false;
  withPython3 = false;
  withRuby = false;

  luaLoader.enable = true;
  performance.byteCompileLua = {
    enable = true;
    configs = true;
    initLua = true;
    nvimRuntime = true;
    plugins = true;
  };

  plugins = {
    diffview.enable = true;
    gitblame.enable = true;
    gitsigns.enable = true;
    luasnip.enable = true;
    noice.enable = true;
    nvim-autopairs.enable = true;
    rainbow-delimiters.enable = true;
    sniprun.enable = true;
    spider.enable = true;
    todo-comments.enable = true;
    vim-surround.enable = true;
  };

  plugins.snacks.settings.notifier.enabled = true;
  plugins.snacks.settings.image.enabled = false;
  extraConfigLuaPost = ''
    vim.ui.select = Snacks.picker.select
  '';
}
