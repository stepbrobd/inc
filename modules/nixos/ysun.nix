{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  socket = "/run/ysun.sock";

  canonical = "ysun.co";
  mirrors = [
    "ysun.fr"
    "ysun.jp"
    "ysun.us"

    "deeznuts.phd"
    "internal.center"
    "stepbrobd.com"
    "xdg.sh"
  ];
in
{
  config = lib.mkIf (hasTag "ysun") {
    systemd.sockets.ysun = {
      description = "Homepage";
      wantedBy = [ "sockets.target" ];
      before = [ "caddy.service" ];
      listenStreams = [ socket ];
      socketConfig = {
        SocketUser = "root";
        SocketGroup = config.services.caddy.group;
        SocketMode = "0660";
      };
    };

    systemd.services.ysun = {
      description = "Homepage";
      requires = [ "ysun.socket" ];
      after = [ "ysun.socket" ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        ExecStart = lib.getExe pkgs.ysun;
        DynamicUser = true;
        PrivateNetwork = true;
        Restart = "always";
        RestartSec = 1;
        SyslogLevel = "err";
      };
    };

    services.caddy = {
      enable = true;

      virtualHosts = lib.genAttrs mirrors
        (_: {
          extraConfig = ''
            import base
            import reports
            redir https://${canonical}{uri} temporary
          '';
        }) // {
        ${canonical}.extraConfig = ''
          import webring

          header X-Served-By "${config.networking.fqdn}"

          reverse_proxy unix/${socket}
        '';
      };
    };
  };
}
