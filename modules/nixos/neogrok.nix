{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.services.neogrok;
  inherit (lib.blueprint.services.neogrok) domain;
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

  config = mkIf cfg.enable {
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
      after = [ "network.target" ];
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
            index.listen = "[::1]:6070";
            general.env.GIT_SSH_COMMAND = "ssh -i ${config.sops.secrets.miroir.path} -o StrictHostKeyChecking=accept-new -o TcpKeepAlive=no -o ServerAliveInterval=10";
          })
        }";
        Restart = "on-failure";
        StateDirectory = "miroir";
      };
    };

    systemd.services.neogrok = {
      description = "Neogrok - code search UI for zoekt";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        HOST = cfg.host;
        PORT = lib.toString cfg.port;
        ZOEKT_URL = "http://[::1]:6070"; # default set from miroir
      };
      serviceConfig = {
        ExecStart = "${pkgs.neogrok}/bin/neogrok";
        Restart = "on-failure";
        DynamicUser = true;
      };
    };
  };
}
