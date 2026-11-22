{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.services.neogrok;
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.neogrok) domain;
  # miroir serves the zoekt api here and neogrok reads from it
  zoekt = "[::1]:6070";
in
{
  options.services.neogrok = {
    enable = mkOption {
      default = false;
      description = "Whether to enable neogrok";
      type = types.bool;
    };

    host = mkOption {
      default = "::1";
      description = "Host to bind to";
      type = types.str;
    };

    port = mkOption {
      default = 6071;
      description = "Port to listen on";
      type = types.port;
    };

  };

  config = lib.mkMerge [
    (mkIf (hasTag "neogrok") {
      services.neogrok.enable = lib.mkDefault true;
    })
    (mkIf cfg.enable {
      users.groups.miroir = { };
      users.users.miroir = {
        group = "miroir";
        description = "Miroir operator";
        createHome = false;
        isSystemUser = true;
      };

      sops.secrets.miroir = {
        owner = "miroir";
        group = "miroir";
        mode = "0400";
      };

      services.caddy = {
        enable = true;
        virtualHosts.${domain}.extraConfig = ''
          import common
          import auth
          reverse_proxy [${cfg.host}]:${lib.toString cfg.port}
        '';
      };

      systemd.services.miroir = {
        description = "Miroir - code search index daemon";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment.HOME = "/var/lib/miroir";
        path = with pkgs; [ git openssh ];
        serviceConfig = {
          User = "miroir";
          Group = "miroir";
          ExecStart = "${pkgs.miroir}/bin/miroir index -c ${
          (pkgs.formats.toml {}).generate
          "miroir.toml"
          (lib.recursiveUpdate (lib.importTOML "${inputs.self}/repos/config.toml") {
            index.listen = zoekt;
            general.env.GIT_SSH_COMMAND = "ssh -i ${config.sops.secrets.miroir.path} -o StrictHostKeyChecking=accept-new -o TcpKeepAlive=no -o ServerAliveInterval=10";
          })
        }";
          Restart = "on-failure";
          StateDirectory = "miroir";
          ProtectSystem = "strict";
          PrivateTmp = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          CapabilityBoundingSet = "";
        };
      };

      systemd.services.neogrok = {
        description = "Neogrok - code search UI for zoekt";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          HOST = cfg.host;
          PORT = lib.toString cfg.port;
          ZOEKT_URL = "http://${zoekt}";
        };
        serviceConfig = {
          ExecStart = "${pkgs.neogrok}/bin/neogrok";
          Restart = "on-failure";
          DynamicUser = true;
          CapabilityBoundingSet = "";
        } // lib.optionalAttrs (cfg.host == "::1") {
          IPAddressDeny = "any";
          IPAddressAllow = "localhost";
        };
      };
    })
  ];
}
