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
