{
  opts = {
    encoding = "utf-8";
    title = true;
    wrap = false;
    number = true;
    relativenumber = true;
    clipboard = "unnamedplus";
    incsearch = true;
    ignorecase = true;
    smartcase = true;
    expandtab = true;
    undofile = true;
    autoindent = true;
    smartindent = true;
    smarttab = true;
    pumheight = 10;
    foldlevel = 99;
    termguicolors = true;

    scrolloff = 8;
    sidescrolloff = 8;
    cursorline = true;
    cursorlineopt = "number";

    splitright = true;
    splitbelow = true;

    updatetime = 250;
    timeoutlen = 300;

    signcolumn = "yes";
    confirm = true;
    shiftwidth = 2;
    tabstop = 2;
    softtabstop = 2;
  };

  autoCmd = [
    {
      event = [ "TextYankPost" ];
      callback.__raw = ''function() vim.hl.on_yank() end'';
      desc = "Highlight yanked text";
    }
  ];
}
