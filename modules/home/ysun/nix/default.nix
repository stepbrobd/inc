{ config, ... }:

{
  sops.secrets."nix.conf/access-tokens" = { mode = "0400"; };

  nix.extraOptions = "!include ${config.sops.secrets."nix.conf/access-tokens".path}";
}
