{
  keymaps = [
    {
      mode = "n";
      key = "<leader>tf";
      action.__raw = ''function() Snacks.terminal.toggle(nil, { win = { position = "float" } }) end'';
      options = { silent = true; desc = "Start a new floating terminal"; };
    }
    {
      mode = "n";
      key = "<leader>th";
      action.__raw = ''function() Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 20 } }) end'';
      options = { silent = true; desc = "Start a new horizontal terminal"; };
    }
    {
      mode = "n";
      key = "<leader>tv";
      action.__raw = ''function() Snacks.terminal.toggle(nil, { win = { position = "right",  width  = 60 } }) end'';
      options = { silent = true; desc = "Start a new vertical terminal"; };
    }
    {
      mode = "n";
      key = "<leader>tx";
      action.__raw = ''
        function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "terminal" then
              vim.api.nvim_win_close(win, true)
            end
          end
        end
      '';
      options = { silent = true; desc = "Quit all terminal sessions"; };
    }
  ];
}
