{ config, ... }:

{
  home.preferXdgDirectories = true;

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      setSessionVariables = true;
      createDirectories = true;
      extraConfig.WORKSPACE = "${config.home.homeDirectory}/Workspace";
    };
  };

  # check with pkgs.xdg-ninja
  home.sessionVariables = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
    MPLCONFIGDIR = "${config.xdg.cacheHome}/matplotlib";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite_history";
  };
}
