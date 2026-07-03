{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.networking.ranet;
  bp = lib.blueprint;
  host = bp.hosts.${config.networking.hostName} or null;
  hasTag = lib.hasTag config.networking.hostName;

  port = (lib.head cfg.settings.endpoints).port;
in
{
  options.networking.ranet = {
    enable = lib.mkEnableOption "ranet IPSec mesh";

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets.ranet.path;
      description = "path to ED25519 private key (PEM format, from sops)";
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        if host != null && host.interface != null
        then [ host.interface ]
        else [ ];
      description = "network interfaces StrongSwan binds to";
    };

    settings = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = (pkgs.formats.json { }).type;

        options = {
          organization = lib.mkOption {
            type = lib.types.str;
            default = bp.ranet.organization;
            description = "organization name in the registry";
          };

          common_name = lib.mkOption {
            type = lib.types.str;
            default = config.networking.hostName;
            description = "node name within the organization";
          };

          endpoints = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf (pkgs.formats.json { }).type);
            default =
              if host != null && host ? ranet && host.ranet ? endpoints
              then host.ranet.endpoints
              else [ ];
            description = "local endpoints (serial_number, address_family, address, port)";
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (hasTag "ranet") {
      networking.ranet.enable = lib.mkDefault true;
      sops.secrets.ranet.mode = "600";
    })

    (lib.mkIf cfg.enable {
      assertions = [{
        assertion = lib.length (lib.unique (lib.map (ep: ep.port) cfg.settings.endpoints)) == 1;
        message = "networking.ranet: endpoints must be non-empty and share one port (charon port_nat_t takes a single value)";
      }];

      # load at boot: net.vrf.strict_mode below doesnt exist until the module is in
      boot.kernelModules = [ "vrf" ];
      boot.kernel.sysctl = {
        "net.vrf.strict_mode" = 1;
        # allow sockets in the default VRF to accept connections arriving
        # via the gravity VRF (services bind to 0.0.0.0/[::] but receive
        # traffic on IPAM addresses which are in the gravity VRF)
        "net.ipv4.tcp_l3mdev_accept" = 1;
        "net.ipv4.udp_l3mdev_accept" = 1;
        "net.ipv4.raw_l3mdev_accept" = 0;
        # ranet creates xfrm interfaces with link/none (no MAC)
        # for which systemd-udev default IPv6AddressGenerationMode falls back to "none" (addr_gen_mode=1)
        # meaning no link-local then also means babel cant run on the interface
        # force "random" at the kernel-level default so fresh interfaces inherit it at creation time
        # before any userspace daemon (udevd/networkd/strongswan) gets a chance to race
        "net.ipv6.conf.default.addr_gen_mode" = 3;
      };

      systemd.network.netdevs."20-gravity" = {
        netdevConfig = {
          Kind = "vrf";
          Name = "gravity";
        };
        vrfConfig.Table = 200;
      };

      systemd.network.networks."20-gravity" = {
        name = "gravity";
        linkConfig.RequiredForOnline = false;
      };

      environment.systemPackages = [
        config.services.strongswan-swanctl.package
        pkgs.ranet
      ];

      environment.etc."ranet/config.json".source =
        let
          # ll addr comes from the addr_gen_mode sysctl above so no addrgenmode fixup is needed here
          updown = pkgs.writeShellScript "updown" ''
            LINK=ranet$(printf '%05x' "$PLUTO_IF_ID_OUT")

            case "$PLUTO_VERB" in
              up-client)
                ip link add "$LINK" type xfrm if_id "$PLUTO_IF_ID_OUT"
                ip link set "$LINK" mtu 1400 multicast on master gravity up
                ;;
              down-client)
                ip link del "$LINK"
                ;;
            esac
          '';
        in
        (pkgs.formats.json { }).generate "ranet.json" (
          cfg.settings // {
            endpoints = lib.map (ep: ep // { inherit updown; }) cfg.settings.endpoints;
          }
        );

      # use the following to only use my nodes
      # environment.etc."ranet/registry.json".source =
      #   (pkgs.formats.json { }).generate "registry.json" [ pkgs.gravity.registry ];

      # use the following to use all gravity nodes
      sops.secrets.gravity = {
        sopsFile = pkgs.gravity.full;
        path = "/etc/ranet/registry.json";
        mode = "444";
        reloadUnits = [ config.systemd.services.ranet.name ];
      };

      systemd.services.ranet =
        let
          ranetExec = subcmd: lib.concatStringsSep " " [
            "${pkgs.ranet}/bin/ranet"
            "--config=/etc/ranet/config.json"
            "--registry=/etc/ranet/registry.json"
            "--key=${cfg.privateKeyFile}"
            subcmd
          ];
        in
        {
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ranetExec "up";
            ExecReload = ranetExec "up";
            ExecStop = ranetExec "down";
          };
          bindsTo = [ "strongswan-swanctl.service" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" "strongswan-swanctl.service" "systemd-networkd.service" ];
          wantedBy = [ "multi-user.target" ];
          reloadTriggers = [
            # must watch this
            config.environment.etc."ranet/config.json".source
            # if using our own nodes
            # config.environment.etc."ranet/registry.json".source
            # full gravity registry updates already reload via sops.secrets.gravity.reloadUnits
          ];
        };

      services.strongswan-swanctl = {
        enable = true;
        strongswan.extraConfig = ''
          charon {
            ikesa_table_size = 32
            ikesa_table_segments = 4
            reuse_ikesa = no
            interfaces_use = ${lib.concatStringsSep "," cfg.interfaces}
            port = 0
            port_nat_t = ${lib.toString port}
            retransmit_timeout = 30
            retransmit_base = 1
            plugins {
              socket-default {
                set_source = yes
                set_sourceif = yes
              }
              dhcp {
                load = no
              }
            }
          }
          charon-systemd {
            journal {
              default = -1
            }
          }
        '';
      };

      # ranet ipsec
      networking.firewall.allowedUDPPorts = [ port ];

      # babel multicast
      networking.firewall.interfaces.gravity.allowedUDPPorts = [ 6696 ];
    })
  ];
}
