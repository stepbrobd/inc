{ config, ... }:

{
  xdg.enable = true;
  xdg.userDirs.enable = true;

  home.sessionVariables = {
    # GOROOT = "${pkgs.go}/share/go"; # set only in direnv
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/pkg/mod";
  };
}
