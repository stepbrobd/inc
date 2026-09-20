{ config, lib, pkgs, ... }:

let
  platforms = [
    "codeberg"
    "github"
    "gitlab"
    "inria"
    "sourcehut"
  ];
in
{
  home.packages = [ pkgs.miroir ];

  xdg.configFile."carapace/choices/miroir".text = "miroir/cobra@bridge\n";
  xdg.configFile."miroir/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/inc/repos/config.toml";

  sops.secrets = lib.genAttrs (map (p: "miroir/${p}") platforms) (_: {
    sopsFile = ./secrets.yaml;
  });

  sops.templates."miroir/auth.toml" = {
    path = "${config.xdg.configHome}/miroir/auth.toml";
    file = (pkgs.formats.toml { }).generate "auth.toml" {
      platform = lib.genAttrs platforms (p: {
        token = config.sops.placeholder."miroir/${p}";
      });
    };
  };
}
