{ config, ... }:

{
  home.preferXdgDirectories = true;

  # check with pkgs.xdg-ninja
  home.sessionVariables = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
  };
}
