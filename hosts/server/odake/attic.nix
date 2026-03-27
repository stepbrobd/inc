{ config, lib, ... }:

{
  services.attic = {
    enable = true;
    settings.listen = "[::1]:10070";
  };

  services.caddy = {
    enable = true;

    virtualHosts.${lib.blueprint.services.attic.domain}.extraConfig = ''
      import common
      reverse_proxy ${config.services.attic.settings.listen}
    '';
  };
}
