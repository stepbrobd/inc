{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.services.sigsci-agent;
  format = pkgs.formats.toml { };
in
{
  options.services.sigsci-agent = {
    enable = lib.mkEnableOption "Fastly Next-Gen WAF agent" // {
      default = config.services.caddy.enable;
    };

    package = lib.mkPackageOption pkgs "sigsci-agent" { };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "/run/sigsci-agent/sigsci.sock";
      description = "RPC unix socket path";
    };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      description = "NGWAF agent.conf";
    };
  };

  config = lib.mkIf cfg.enable {
    # SIGSCI_ACCESSKEYID
    # SIGSCI_SECRETACCESSKEY
    sops.secrets.sigsci = { };

    services.sigsci-agent.settings = lib.mapAttrs (_: lib.mkDefault) {
      local-networks = "none";
      max-procs = "100%";
      rpc-address = "unix:${cfg.socket}";
      server-hostname = config.networking.fqdn;
      shared-cache-dir = "/var/cache/sigsci-agent";
    };

    users.users.sigsci-agent = {
      isSystemUser = true;
      group = config.services.caddy.group;
    };

    systemd.services.sigsci-agent = {
      description = "Fastly Next-Gen WAF agent";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      before = [ "caddy.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --config=${format.generate "agent.conf" cfg.settings}";
        EnvironmentFile = [ config.sops.secrets.sigsci.path ];
        Restart = "on-failure";
        RestartSec = 5;
        User = "sigsci-agent";
        Group = config.services.caddy.group;
        UMask = "0007";
        RuntimeDirectory = "sigsci-agent";
        RuntimeDirectoryMode = "0750";
        CacheDirectory = "sigsci-agent";
        CacheDirectoryMode = "0750";
        MemoryMax = "256M";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
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
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
