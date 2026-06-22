{ lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib)
    types
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.openvpn;

  mkOpenVPN =
    name: conf:
    (pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ cfg.package ];
      text = "openvpn ${conf}";
    });
in
{
  options.programs.openvpn = {
    enable = mkEnableOption "OpenVPN client" // {
      default = true;
    };

    package = mkPackageOption pkgs "openvpn" { };

    accounts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              execName = mkOption {
                type = types.str;
                description = "Output executable name of the VPN account";
                default = "openvpn-${name}";
              };

              confFile = mkOption {
                type = types.path;
                description = "Path to the VPN connection configuration file";
              };
            };
          }
        )
      );
      default = { };
      description = "Accounts to use for OpenVPN";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ]
    ++ (lib.mapAttrsToList (_: attrs: with attrs; mkOpenVPN execName confFile) cfg.accounts);

    sops.secrets."openvpn/g5k" = { sopsFile = ./secrets.yaml; };
    programs.openvpn.accounts.g5k.confFile = config.sops.secrets."openvpn/g5k".path;
  };
}
