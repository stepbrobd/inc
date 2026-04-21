{
  plugins.web-devicons.enable = true;
  plugins.snacks.settings.picker.layout.preset = "default";
  keymaps = [
    {
      mode = "n";
      key = "<leader>ff";
      action.__raw = "function() Snacks.picker.files() end";
      options = { silent = true; desc = "Find files"; };
    }
    {
      mode = "n";
      key = "<leader>fg";
      action.__raw = "function() Snacks.picker.grep() end";
      options = { silent = true; desc = "Live grep"; };
    }
    {
      mode = "n";
      key = "<leader>fb";
      action.__raw = "function() Snacks.picker.buffers() end";
      options = { silent = true; desc = "List buffers"; };
    }
  ];
}
