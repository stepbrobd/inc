{ lib, ... }:

{ config, pkgs, ... }:

{
  home.packages = [ pkgs.niks3 ];

  sops.secrets."niks3/niks3-api-token" = { };

  home.sessionVariables = {
    # api.cache.ysun.co (upload api)
    NIKS3_SERVER_URL = "https://${lib.blueprint.services.niks3.domain}";
    NIKS3_AUTH_TOKEN_FILE = config.sops.secrets."niks3/niks3-api-token".path;
  };
}
