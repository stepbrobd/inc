{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.networking.ranet3;
  bp = lib.blueprint;
  host = bp.hosts.${config.networking.hostName} or null;
  hasTag = lib.hasTag config.networking.hostName;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isServer = host.type == "server";

  table = 200;
  # SO_MARK on the underlay socket
  # priority 40 rule keeps it in main
  # exit announced default never carries the tunnel inside itself
  mark = 29292; # 0x726c

  ipam4 = "${host.ipam.ipv4}/32";
  ipam6 = "${host.ipam.ipv6}/128";

  # one port per leaf
  # two leaves behind one nat on a shared port lose flows to the collision
  port = (lib.head host.ranet.endpoints).port;

  # 2a0c:b641:69c:xxx0::/60 -> "2a0c:b641:69c:xxx", <base>6::/64 holds the srv6 sids pkgs/gravity publishes
  gravityBase = lib.removeSuffix "0::/60" host.ranet.gravity.prefix;

  metrics = "[::1]:9325";
in
{
  # the platform module comes from inputs.ranet3 in modules/nixos/minimal.nix
  # and in the darwin module list of modules/flake/configurations.nix
  imports = [
    # systemd only (nix-darwin dont have these options)
    ({ options, ... }: {
      config = lib.optionalAttrs (options ? systemd) (lib.mkIf (hasTag "ranet3") {
        sops.secrets.ranet.restartUnits = [ config.systemd.services.ranet3.name ];
        sops.secrets.gravity.reloadUnits = [ config.systemd.services.ranet3.name ];

        users.users.ysun.extraGroups = [ cfg.group ];

        # networkd drops rules that did not request on resume/restart
        systemd.network.config.networkConfig = {
          ManageForeignRoutingPolicyRules = lib.mkDefault false;
          ManageForeignRoutes = lib.mkDefault false;
        };

        networking.ranet3.extraArgs = lib.mkIf config.services.victoriametrics.enable [ "--metrics" metrics ];
        services.victoriametrics.prometheusConfig.scrape_configs = lib.mkIf config.services.victoriametrics.enable [{
          job_name = "ranet3";
          static_configs = [{ targets = [ metrics ]; }];
        }];
      });
    })

    # a server keeps the gravity vrf and the srv6 sids ranet.nix gives a router
    # as10779 puts dummy0 and the rules in the vrf
    # pkgs/gravity have ::1 and ::2
    ({ options, ... }: {
      config = lib.optionalAttrs (options ? systemd) (lib.mkIf (hasTag "ranet3" && isServer) {
        boot.kernelModules = [ "vrf" ];
        boot.kernel.sysctl = {
          "net.vrf.strict_mode" = 1;
          "net.ipv4.tcp_l3mdev_accept" = 1;
          "net.ipv4.udp_l3mdev_accept" = 1;
          "net.ipv4.raw_l3mdev_accept" = 0;
          "net.ipv4.conf.ranet3.rp_filter" = 0;
        };

        networking.firewall.checkReversePath = lib.mkDefault "loose";

        systemd.network.netdevs."20-gravity" = {
          netdevConfig = {
            Kind = "vrf";
            Name = "gravity";
          };
          vrfConfig.Table = table;
        };

        systemd.network.networks."20-gravity" = {
          name = "gravity";
          linkConfig.RequiredForOnline = false;
          routingPolicyRules = lib.map
            (from: { Family = "ipv6"; From = from; To = "${gravityBase}6::/64"; Table = 100; Priority = 50; })
            bp.net.gravity.ipv6;
        };

        networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [
          "interface-name:dummy0"
          "interface-name:gravity"
        ];

        networking.iproute2.enable = true;
        networking.iproute2.rttablesExtraConfig = ''
          100 localsid
        '';

        systemd.services.ranet3-srv6 =
          let
            routes = [
              "blackhole default table localsid"
              "${gravityBase}6::1 encap seg6local action End.DT46 vrftable ${toString table} dev gravity table localsid"
              "${gravityBase}6::2 encap seg6local action End dev gravity table localsid"
            ];
          in
          {
            description = "SRv6 local SIDs for the gravity mesh";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStartPre = pkgs.writeShellScript "gravity-wait-up" ''
                export PATH=${lib.makeBinPath (with pkgs; [ iproute2 gnugrep coreutils ])}
                for _ in $(seq 60); do
                  ip link show dev gravity up 2>/dev/null | grep -q gravity && exit 0
                  sleep 1
                done
                echo "gravity not up after 60s" >&2
                exit 1
              '';
              ExecStart = lib.map (r: "${pkgs.iproute2}/bin/ip -6 route replace ${r}") routes;
              ExecStartPost = "${pkgs.iproute2}/bin/ip sr tunsrc set ${gravityBase}0::1";
              ExecStop = lib.map (r: "-${pkgs.iproute2}/bin/ip -6 route del ${r}") routes;
              ExecStopPost = "-${pkgs.iproute2}/bin/ip sr tunsrc set ::";
            };
            after = [ "network-online.target" "systemd-networkd.service" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
          };
      });
    })
  ];

  # every host but a router, whose exit stays on ranet
  # darwin installs the exit defaults scoped to the utun and the mesh's more specifics unscoped
  config = lib.mkIf (hasTag "ranet3") {
    assertions = [
      {
        assertion = !(config.networking.ranet.enable or false);
        message = "ranet3 and ranet both own routing table 200, tag a host with one of them";
      }
      {
        assertion = host != null && !(hasTag "router") && host.ipam ? ipv4 && host.ipam ? ipv6 && host.ranet ? endpoints && (isServer -> host.ranet ? gravity);
        message = "ranet3 needs a blueprint host that is not a router, with ipam.ipv4, ipam.ipv6, ranet.endpoints and on a server ranet.gravity";
      }
    ];

    sops.secrets.ranet.mode = "600";
    sops.secrets.gravity.sopsFile = pkgs.gravity.full;

    networking.ranet3 = {
      enable = true;
      openFirewall = isServer;
      settings = {
        node = "${bp.ranet.organization}/${config.networking.hostName}";
        auth = {
          trust = config.sops.secrets.gravity.path;
          key = config.sops.secrets.ranet.path;
        };
        link = {
          inherit port;
          # largest inner packet a session carries
          # ranet3 clamps the mss of tcp syns crossing the tun to it
          mtu = 1400;
          endpoints = lib.map (ep: { serial = ep.serial_number; family = ep.address_family; }) host.ranet.endpoints;
          listen = lib.mkIf isServer true;
          # a server has a provider address in each family for the underlay to leave from
          underlay = lib.mkIf (isLinux && !isServer) { inherit mark; };
        };
        dial.all = true;
        cap.route = {
          # a server's srv6 sids and gravity address sit in its /60
          announce = [ ipam4 ipam6 ] ++ lib.optional isServer host.ranet.gravity.prefix;
          transit = isServer;
        };
        # on a server networkd owns the vrf
        # dummy0 carries the ipam pair and as10779 the rules
        cap.table =
          if isServer then {
            id = table;
            prefsrc4 = host.ipam.ipv4;
            vrf.name = "gravity";
          } else {
            addresses = [ ipam4 ipam6 ];
            id = lib.mkIf isLinux table;
            rules = lib.mkIf isLinux ([
              { fwmark = mark; table = "main"; priority = 40; family = "both"; }
            ]
            ++ lib.map (to: { inherit to table; priority = 100; }) bp.net.gravity.ipv6
            ++ lib.map (from: { inherit from table; priority = 150; }) [ ipam4 ipam6 ]);
          };
      };
    };
  };
}
