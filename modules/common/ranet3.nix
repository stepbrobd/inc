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

    ({ options, ... }: {
      config = lib.optionalAttrs (options ? systemd) (lib.mkIf (hasTag "ranet3" && isServer) {
        boot.kernel.sysctl = {
          "net.ipv4.conf.ranet3.rp_filter" = 0;
          "net.ipv4.ip_nonlocal_bind" = 1;
          "net.ipv6.ip_nonlocal_bind" = 1;
        };

        networking.firewall.checkReversePath = lib.mkDefault "loose";

        networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [
          "interface-name:dummy0"
        ];
      });
    })

    # a router is the mesh's exit for the space bgp announces and its ingress from the internet
    ({ options, ... }: {
      config = lib.optionalAttrs (options ? systemd) (lib.mkIf (hasTag "ranet3" && hasTag "router") (
        let
          as = config.services.as10779;
          exits = as.router.exit && as.router.advertiseDefault;
        in
        {
          boot.kernelModules = [ "nf_conntrack" ];
          boot.kernel.sysctl."net.netfilter.nf_conntrack_max" = 262144;

          networking.ranet3.settings = {
            cap.route.announce =
              # the anycast pair stays on dummy0
              # since the kernel takes a source for a route through the tun from the tun's own addresses
              lib.subtractLists [ ipam4 ipam6 ] (as.local.ipv4.addresses ++ as.local.ipv6.addresses)
              # ipv6 exits only for the sources bgp announces
              ++ lib.optionals exits (lib.map (r: { prefix = "::/0"; from = r.prefix; }) as.router.static.ipv6.routes);
            cap.egress = {
              advertise = lib.optional exits "0.0.0.0/0";
              # the exit tracks replies to traffic that came in by another router
              flows_per_source = 1048576;
              translate =
                # bgp announces these
                lib.map (r: { from = r.prefix; to = "none"; }) (as.router.static.ipv4.routes ++ as.router.static.ipv6.routes)
                # any other source leaves as this node's ipam pair
                ++ [
                  { from = "0.0.0.0/0"; to = host.ipam.ipv4; }
                  { from = "::/0"; to = host.ipam.ipv6; }
                ];
            };
            cap.segment.local = [{
              sid = "${gravityBase}6::3";
              behavior = "End.DT46";
              deliver = "egress";
              # our own nodes alone including all outer and inner sources
              allow = lib.map (h: h.ranet.gravity.prefix) (lib.filter (h: h.ranet ? gravity) (lib.attrValues bp.hosts));
            }];
          };
        }
      ));
    })
  ];

  # darwin installs the exit defaults scoped to the utun and the mesh's more specifics unscoped
  config = lib.mkIf (hasTag "ranet3") {
    assertions = [
      {
        assertion = host != null && host.ipam ? ipv4 && host.ipam ? ipv6 && host.ranet ? endpoints && (isServer -> host.ranet ? gravity) && (hasTag "router" -> isServer);
        message = "ranet3 needs a blueprint host with ipam.ipv4, ipam.ipv6, ranet.endpoints, on a server ranet.gravity, and a router that is a server";
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
        };
        dial.all = true;
        cap.route = {
          # a server's srv6 sids and gravity address sit in its /60
          announce = [ ipam4 ipam6 ] ++ lib.optional isServer host.ranet.gravity.prefix;
        };
        cap.transit.enable = isServer;
        cap.babel.cost.extra.foreign = 32;
        # darwin refuses cap.border at startup
        cap.border = lib.mkIf isLinux {
          overlay = bp.net.ipam.ipv4 ++ bp.net.ipam.ipv6 ++ bp.net.gravity.ipv6;
        };
        cap.segment = lib.mkIf isServer {
          local = [
            { sid = "${gravityBase}6::1"; behavior = "End.DT46"; }
            { sid = "${gravityBase}6::2"; behavior = "End"; }
          ];
        };
        cap.table = {
          addresses = [ ipam4 ipam6 ] ++ lib.optional isServer "${gravityBase}0::1/60";
          id = lib.mkIf isLinux table;
        };
      };
    };
  };
}
