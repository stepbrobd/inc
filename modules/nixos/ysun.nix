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
        SocketUser = config.services.caddy.user;
        SocketMode = "0600";
      };
    };

    systemd.services.ysun = {
      description = "Homepage";
      requires = [ "ysun.socket" ];
      after = [ "ysun.socket" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        ExecStart = lib.getExe pkgs.ysun;
        Restart = "always";
        RestartSec = 1;
        SyslogLevel = "err";
        DynamicUser = true;
        UMask = "0077";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
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
