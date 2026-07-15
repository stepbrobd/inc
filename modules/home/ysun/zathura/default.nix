{
  programs.zathura = {
    enable = true;

    extraConfig = ''
      set database            sqlite
      set guioptions          none
      set selection-clipboard clipboard

      set render-loading      "true"
      set recolor             "true"
    '';
  };
}
