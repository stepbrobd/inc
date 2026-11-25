{ config, ... }:

let
  variables = {
    # GOROOT = "${pkgs.go}/share/go"; # set only in direnv
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/pkg/mod";
  };
in
{
  xdg.enable = true;
  xdg.userDirs.enable = true;

  home.sessionVariables = variables;
  systemd.user.sessionVariables = variables;
}
