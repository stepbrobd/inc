{ config, ... }:

{
  # see settings from git module
  programs.delta = {
    enable = true;
    enableJujutsuIntegration = true;
    options = {
      features = "collared-trogon";
      navigate = true;
      side-by-side = true;
    };
  };

  programs.jujutsu = {
    enable = true;

    settings = {
      user = with config.programs.git.settings.user; {
        inherit name email;
      };

      signing = {
        behavior = "own";
        backend = "ssh";
        key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };

      ui = {
        conflict-marker-style = "diff";
        default-command = "status";
        log-word-wrap = true;
      };
    };
  };
}
