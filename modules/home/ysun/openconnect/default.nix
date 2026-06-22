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

  cfg = config.programs.openconnect;

  mkOpenConnect =
    name: userFile: passFile: authGroupFile: connFile:
    (pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.coreutils
        cfg.package
      ];
      text = ''
        openconnect \
          --protocol=anyconnect \
          --passwd-on-stdin \
          --user="$(cat ${userFile})" \
          --authgroup="$(cat ${authGroupFile})" \
          "$(cat ${connFile})" < ${passFile}
      '';
    });
in
{
  options.programs.openconnect = {
    enable = mkEnableOption "OpenConnect client" // {
      default = true;
    };

    package = mkPackageOption pkgs "openconnect" { };

    accounts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              execName = mkOption {
                type = types.str;
                description = "Output executable name of the VPN account";
                default = "openconnect-${name}";
              };

              userFile = mkOption {
                type = types.path;
                description = "Path to the VPN user file";
              };

              passFile = mkOption {
                type = types.path;
                description = "Path to the VPN password file";
              };

              authGroupFile = mkOption {
                type = types.path;
                description = "Path to authentication group";
              };

              connFile = mkOption {
                type = types.path;
                description = "Path to the VPN connection URL";
              };
            };
          }
        )
      );
      default = { };
      description = "Accounts to use for OpenConnect";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ]
    ++ (lib.mapAttrsToList
      (_: attrs: with attrs;
      mkOpenConnect
        execName
        userFile
        passFile
        authGroupFile
        connFile)
      cfg.accounts);

    sops.secrets."openconnect/inria/user" = { sopsFile = ./secrets.yaml; };
    sops.secrets."openconnect/inria/pass" = { sopsFile = ./secrets.yaml; };
    sops.secrets."openconnect/inria/agfp" = { sopsFile = ./secrets.yaml; };
    sops.secrets."openconnect/inria/conn" = { sopsFile = ./secrets.yaml; };
    programs.openconnect.accounts.inria = {
      userFile = config.sops.secrets."openconnect/inria/user".path;
      passFile = config.sops.secrets."openconnect/inria/pass".path;
      authGroupFile = config.sops.secrets."openconnect/inria/agfp".path;
      connFile = config.sops.secrets."openconnect/inria/conn".path;
    };


    sops.secrets."openconnect/grenet/user" = { sopsFile = ./secrets.yaml; };
    sops.secrets."openconnect/grenet/pass" = { sopsFile = ./secrets.yaml; };
    sops.secrets."openconnect/grenet/agfp" = { sopsFile = ./secrets.yaml; };
    sops.secrets."openconnect/grenet/conn" = { sopsFile = ./secrets.yaml; };
    programs.openconnect.accounts.grenet = {
      userFile = config.sops.secrets."openconnect/grenet/user".path;
      passFile = config.sops.secrets."openconnect/grenet/pass".path;
      authGroupFile = config.sops.secrets."openconnect/grenet/agfp".path;
      connFile = config.sops.secrets."openconnect/grenet/conn".path;
    };
  };
}
