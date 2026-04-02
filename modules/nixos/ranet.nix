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
      environment.systemPackages = [
        config.services.strongswan-swanctl.package
        pkgs.ranet
      ];

      environment.etc."ranet/config.json".source = (pkgs.formats.json { }).generate "ranet.json" (
        cfg.settings // {
          endpoints = lib.map
            (ep: ep // {
              updown = pkgs.writeShellScript "updown" ''
                LINK=ranet$(printf '%05x' "$PLUTO_IF_ID_OUT")
                case "$PLUTO_VERB" in
                  up-client)
                    ip link add "$LINK" type xfrm if_id "$PLUTO_IF_ID_OUT"
                    ip link set "$LINK" multicast on mtu 1400 up
                    ;;
                  down-client)
                    ip link del "$LINK"
                    ;;
                esac
              '';
            })
            cfg.settings.endpoints;
        }
      );

      environment.etc."ranet/registry.json".source =
        (pkgs.formats.json { }).generate "registry.json" [ pkgs.gravity.passthru.registry ];

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
          wants = [ "network-online.target" "strongswan-swanctl.service" ];
          after = [ "network-online.target" "strongswan-swanctl.service" ];
          wantedBy = [ "multi-user.target" ];
          reloadTriggers = [ config.environment.etc."ranet/config.json".source ];
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

      networking.firewall.allowedUDPPorts = [ port ];
    })
  ];
}
