{
  plugins.snacks = {
    enable = true;

    settings.styles = {
      float.backdrop = false;
      input.backdrop = false;
      notification.backdrop = false;
    };

    settings.dashboard = {
      preset = {
        header = ''
          ███████╗███╗   ███╗ █████╗  ██████╗███████╗
          ██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝
          █████╗  ██╔████╔██║███████║██║     ███████╗
          ██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║
          ███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║
          ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
        '';
        keys = [
          { icon = " "; key = "n"; desc = "New File"; action = ":ene | startinsert"; }
          { icon = " "; key = "f"; desc = "Find File"; action.__raw = "function() Snacks.picker.files() end"; }
          { icon = " "; key = "g"; desc = "Live Grep"; action.__raw = "function() Snacks.picker.grep() end"; }
          { icon = " "; key = "q"; desc = "Quit"; action = ":qa"; }
        ];
      };

      sections = [
        { padding = 4; }
        { text = "not"; align = "center"; hl = "Type"; }
        { padding = 1; }
        { section = "header"; }
        { padding = 2; }
        { section = "keys"; gap = 0; padding = 1; }
        { padding = 2; }
        { text = "its neovim"; align = "center"; hl = "Type"; }
      ];
    };
  };
}
