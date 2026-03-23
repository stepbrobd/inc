{ lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption mkMerge mkPackageOption mkOption types optional;

  cfg = config.services.ripe-atlas-software-probe;

  hostBp = lib.blueprint.hosts.${config.networking.hostName} or { };
  ipam = hostBp.ipam or { };
  bpInterface = ipam.interface or hostBp.interface or null;
  bpIpv4 = ipam.ipv4 or hostBp.ipv4 or null;
  bpIpv6 = ipam.ipv6 or hostBp.ipv6 or null;

  pkg = cfg.package.override {
    withUser = cfg.user;
    withGroup = cfg.group;
    withMeasurementUser = cfg.user;
  };

  # override measurements to pick up the same software probe (with correct user
  # in measurement.conf) the C code reads ATLAS_DATADIR from atlas_path.h
  measurements = pkgs.ripe-atlas-probe-measurements.override {
    ripe-atlas-software-probe = pkg;
  };

  hasSourceRouting = cfg.sourceAddress4 != null || cfg.sourceAddress6 != null;

  setup = pkgs.writeShellScript "ripe-atlas-setup" ''
    # copy read-only config files from the store to the writable config dir
    for f in mode; do
      [ -f /etc/ripe-atlas/$f ] || cp ${pkg}/etc/ripe-atlas/$f /etc/ripe-atlas/$f
    done
  '';

  table = toString cfg.routingTable;

  # policy routing: force all probe traffic through a specific interface/address.
  # uid is resolved at runtime because isSystemUser gets auto-assigned at activation
  # copy the main table's default route but override the source address.
  # packets still exit through the real gateway the interface option only
  # determines which address is used as the source
  routeSetup = pkgs.writeShellScript "ripe-atlas-route-setup" ''
    uid=$(id -u ${cfg.user})
    ${lib.optionalString (cfg.sourceAddress4 != null) ''
      gw4=$(ip -4 route show default | head -1 | sed 's/^default //')
      ip -4 rule del uidrange $uid-$uid lookup ${table} 2>/dev/null || true
      ip -4 rule add uidrange $uid-$uid lookup ${table}
      ip -4 route replace default $gw4 src ${cfg.sourceAddress4} table ${table}
    ''}
    ${lib.optionalString (cfg.sourceAddress6 != null) ''
      gw6=$(ip -6 route show default | head -1 | sed 's/^default //')
      ip -6 rule del uidrange $uid-$uid lookup ${table} 2>/dev/null || true
      ip -6 rule add uidrange $uid-$uid lookup ${table}
      ip -6 route replace default $gw6 src ${cfg.sourceAddress6} table ${table}
    ''}
  '';

  routeTeardown = pkgs.writeShellScript "ripe-atlas-route-teardown" ''
    uid=$(id -u ${cfg.user})
    ip -4 rule del uidrange $uid-$uid lookup ${table} 2>/dev/null || true
    ip -6 rule del uidrange $uid-$uid lookup ${table} 2>/dev/null || true
    ip -4 route flush table ${table} 2>/dev/null || true
    ip -6 route flush table ${table} 2>/dev/null || true
  '';
in
{
  options.services.ripe-atlas-software-probe = {
    enable = mkEnableOption "RIPE Atlas software probe";

    package = mkPackageOption pkgs "ripe-atlas-software-probe" { };

    user = mkOption {
      default = "ripe-atlas";
      description = "user to run the probe and measurement processes as";
      type = types.str;
    };

    group = mkOption {
      default = "ripe-atlas";
      description = "group to run the probe process as";
      type = types.str;
    };

    interface = mkOption {
      default = bpInterface;
      description = "outgoing interface for probe traffic";
      type = types.nullOr types.str;
    };

    sourceAddress4 = mkOption {
      default = bpIpv4;
      description = "IPv4 source address for probe traffic";
      type = types.nullOr types.str;
    };

    sourceAddress6 = mkOption {
      default = bpIpv6;
      description = "IPv6 source address for probe traffic";
      type = types.nullOr types.str;
    };

    routingTable = mkOption {
      default = 100;
      description = "routing table number for source address policy routing";
      type = types.int;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = hasSourceRouting -> cfg.interface != null;
          message = "services.ripe-atlas-software-probe.interface must be set when using sourceAddress4/sourceAddress6";
        }
      ];

      users.groups.${cfg.group} = { };

      users.users.${cfg.user} = {
        group = cfg.group;
        description = "RIPE Atlas probe daemon";
        home = "/var/spool/ripe-atlas";
        createHome = false;
        isSystemUser = true;
      };

      # spool directories matching upstream install-exec-local
      systemd.tmpfiles.rules =
        let
          d = mode: path: "d ${path} ${mode} ${cfg.user} ${cfg.group} -";
          cronDirs = map toString (lib.range 2 20);
        in
        [
          (d "2775" "/var/spool/ripe-atlas")
          (d "2775" "/var/spool/ripe-atlas/data")
          (d "2775" "/var/spool/ripe-atlas/data/new")
          (d "2775" "/var/spool/ripe-atlas/data/oneoff")
          (d "2775" "/var/spool/ripe-atlas/data/out")
          (d "2775" "/var/spool/ripe-atlas/data/out/ooq")
          (d "2775" "/var/spool/ripe-atlas/data/out/ooq10")
          (d "2775" "/var/spool/ripe-atlas/crons")
          (d "2775" "/var/spool/ripe-atlas/crons/main")
          (d "0770" "/etc/ripe-atlas")
        ]
        ++ map (n: d "2775" "/var/spool/ripe-atlas/crons/${n}") cronDirs;

      systemd.services.ripe-atlas-software-probe = {
        description = "RIPE Atlas Software Probe";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        path = with pkgs; [
          pkg
          measurements
          coreutils
          iproute2
          net-tools
          openssh
          procps
        ];

        environment = {
          HOME = "/var/spool/ripe-atlas";
          ATLAS_MEASUREMENT = "${measurements}/libexec/ripe-atlas/measurement";
          ATLAS_SYSCONFDIR = "/etc/ripe-atlas";
        };

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "/var/spool/ripe-atlas";
          ExecStartPre = [ "${setup}" ]
            ++ optional hasSourceRouting "+${routeSetup}";
          ExecStart = "${pkg}/sbin/ripe-atlas";
          ExecStopPost = optional hasSourceRouting "+${routeTeardown}";
          Restart = "always";
          TimeoutStopSec = 60;
          KillMode = "control-group";

          RuntimeDirectory = "ripe-atlas";
          RuntimeDirectoryMode = "0775";

          AmbientCapabilities = [ "CAP_NET_RAW" ];

          ProtectHome = true;
          PrivateTmp = true;
          RemoveIPC = true;
        };
      };
    }
  ]);
}
