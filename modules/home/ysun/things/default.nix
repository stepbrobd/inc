{ lib, ... }:

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ aniremind things ];

  sops.secrets."things/email" = { sopsFile = ./secrets.yaml; };
  sops.secrets."things/password" = { sopsFile = ./secrets.yaml; };

  sops.templates."things/auth.json" = {
    path = "${config.xdg.configHome}/things/auth.json";
    content = lib.toJSON {
      email = config.sops.placeholder."things/email";
      password = config.sops.placeholder."things/password";
    };
  };
}
