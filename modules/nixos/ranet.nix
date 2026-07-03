{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.networking.ranet;
  bp = lib.blueprint;
  host = bp.hosts.${config.networking.hostName} or null;
  hasTag = lib.hasTag config.networking.hostName;

  port = (lib.head cfg.settings.endpoints).port;

  # 2a0c:b641:69c:xxx0::/60 -> "2a0c:b641:69c:xxx" for the per-node nibble
  # subspaces: <base>6::/64 = srv6 SIDs
  gravityBase =
    let p = if host != null && host ? ranet && host.ranet ? gravity then host.ranet.gravity.prefix else null;
    in if p != null && lib.hasSuffix "0::/60" p then lib.removeSuffix "0::/60" p else null;

  # ::3 exists on bgp exit routers only
  srv6Exit = config.services.as10779.enable && config.services.as10779.router.exit;

  # all of our own /60s, for scoping ::3 invocation to our nodes
  ownGravityPrefixes = lib.map (h: h.ranet.gravity.prefix)
    (lib.collect (h: h ? ranet && h.ranet ? gravity) bp.hosts);
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

    # srv6: publish segment routing SIDs from the node prefix's "6" nibble subspace
    # so mesh members can steer traffic through explicit waypoints
    #   <base>6::1 = End.DT46 decap into table 200 (exit here, v4 or v6 inner)
    #   <base>6::2 = End      forward to the next SID (transit waypoint)
    #   <base>6::3 = End.DT46 decap into the egress vrf (exit with announced ipam ip)
    #   <base>6::16+ reserved for End.B6.Encaps named paths
    # ::1/::2 are mesh wide and in the registry, ::3 is own nodes only
    # networkd/bird cant install seg6local lwtunnel routes so a oneshot does
    (lib.mkIf (cfg.enable && gravityBase != null) {
      networking.iproute2.enable = true;
      networking.iproute2.rttablesExtraConfig = ''
        100 localsid
        101 exitsid
      '';

      systemd.network.networks."20-gravity".routingPolicyRules = [
        {
          Family = "ipv6";
          From = "2a0c:b641:69c::/48";
          To = "${gravityBase}6::/64";
          Table = 100;
          Priority = 50;
        }
      ]
      # ::3 is matched at 45 for our own sources only
      # everyone else falls through to the mesh wide rule and the localsid blackhole eats it
      ++ lib.optionals srv6Exit (lib.map
        (p: {
          Family = "ipv6";
          From = p;
          To = "${gravityBase}6::3/128";
          Table = 101;
          Priority = 45;
        })
        ownGravityPrefixes);

      systemd.services.ranet-srv6 =
        let
          routes = [
            "blackhole default table localsid"
            "${gravityBase}6::1 encap seg6local action End.DT46 vrftable 200 dev gravity table localsid"
            "${gravityBase}6::2 encap seg6local action End dev gravity table localsid"
          ] ++ lib.optionals srv6Exit [
            "blackhole default table exitsid"
            "${gravityBase}6::3 encap seg6local action End.DT46 vrftable 201 dev gravity table exitsid"
          ];
        in
        {
          description = "SRv6 local SIDs for the gravity mesh";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.map (r: "${pkgs.iproute2}/bin/ip -6 route replace ${r}") routes;
            ExecStop = lib.map (r: "-${pkgs.iproute2}/bin/ip -6 route del ${r}") routes;
          };
          after = [ "network-online.target" "systemd-networkd.service" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
        };
    })

    # ::3 lands in the egress vrf then leaks to main for provider egress
    # SNAT to the node unique ipam /32+/128 instead of masquerade
    # returns enter the nearest exit via anycast and babel carries them back here
    # for conntrack reversal
    # announced space is anycast
    # ipam is the only return deterministic address we announce
    (lib.mkIf (cfg.enable && gravityBase != null && srv6Exit) {
      systemd.network.netdevs."30-egress" = {
        netdevConfig = {
          Kind = "vrf";
          Name = "egress";
        };
        vrfConfig.Table = 201;
      };

      systemd.network.networks."30-egress" = {
        name = "egress";
        linkConfig.RequiredForOnline = false;
        # table 201 stays empty
        # decapped traffic uses mains default routes
        routingPolicyRules = [{
          Family = "both";
          IncomingInterface = "egress";
          Table = "main";
          Priority = 900;
        }];
      };

      networking.nftables.tables.srv6 = {
        family = "inet";
        content = ''
          chain postrouting {
            # priority 90: bind nat before the masquerade chains at srcnat
            type nat hook postrouting priority 90; policy accept;
            iifname "egress" snat ip to ${host.ipam.ipv4}
            iifname "egress" snat ip6 to ${host.ipam.ipv6}
          }
        '';
      };
    })

    # TODO: remove after rpi kernel update?
    # on pre 6.19 kernels (isere with rpi vendor kernel)
    # xfrm interfaces still race with systemd-udev over addr_gen_mode
    # when many SAs are created at once (boot/switch restarting strongswan)
    # the timer scans for broken ifaces and bounces them
    (lib.mkIf (cfg.enable && lib.versionOlder config.boot.kernelPackages.kernel.version "6.19") {
      systemd.services.ranet-ll-heal = {
        description = "Heal ranet interfaces missing IPv6 link-local";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "ranet-ll-heal" ''
            export PATH=${lib.makeBinPath (with pkgs; [ iproute2 gnugrep gawk ])}
            for ifname in $(ip -br link show | awk '/ranet/ {sub(/@.*/, "", $1); print $1}'); do
              if ! ip -6 addr show dev "$ifname" 2>/dev/null | grep -q 'fe80::'; then
                ip link set "$ifname" down
                ip link set dev "$ifname" addrgenmode random
                ip link set "$ifname" up
              fi
            done
          '';
        };
      };
      systemd.timers.ranet-ll-heal = {
        description = "Periodically heal ranet interfaces missing IPv6 link-local";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "30s";
          OnUnitActiveSec = "30s";
          AccuracySec = "5s";
        };
      };
    })
  ];
}
