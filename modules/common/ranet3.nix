{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.networking.ranet3;
  bp = lib.blueprint;
  host = bp.hosts.${config.networking.hostName} or null;
  hasTag = lib.hasTag config.networking.hostName;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

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

  # my own nodes only
  trust = (pkgs.formats.json { }).generate "trust.json" [ pkgs.gravity.registry ];
in
{
  # the platform module comes from inputs.ranet3 in modules/nixos/minimal.nix
  # and in the darwin module list of modules/flake/configurations.nix
  imports = [
    # systemd only, nix-darwin has none of these options
    ({ options, ... }: {
      config = lib.optionalAttrs (options ? systemd) (lib.mkIf (hasTag "ranet3") {
        sops.secrets.ranet.restartUnits = [ config.systemd.services.ranet3.name ];

        users.users.ysun.extraGroups = [ cfg.group ];

        # networkd drops rules that did not request on resume/restart
        systemd.network.config.networkConfig = {
          ManageForeignRoutingPolicyRules = lib.mkDefault false;
          ManageForeignRoutes = lib.mkDefault false;
        };
      });
    })
  ];

  # currently keep this leaf only
  # darwin installs the exit defaults scoped to the utun and the mesh's more specifics unscoped
  config = lib.mkIf (hasTag "ranet3") {
    assertions = [
      {
        assertion = !(config.networking.ranet.enable or false);
        message = "ranet3 and ranet both own routing table 200, tag a host with one of them";
      }
      {
        assertion = host != null && host.type != "server" && host.ipam ? ipv4 && host.ipam ? ipv6 && host.ranet ? endpoints;
        message = "ranet3 needs a non-server blueprint host with ipam.ipv4, ipam.ipv6 and ranet.endpoints";
      }
    ];

    sops.secrets.ranet.mode = "600";

    networking.ranet3 = {
      enable = true;
      settings = {
        node = {
          org = bp.ranet.organization;
          name = config.networking.hostName;
        };
        auth = {
          inherit trust;
          key = config.sops.secrets.ranet.path;
        };
        link = {
          inherit port;
          # largest inner packet a session carries
          # ranet3 clamps the mss of tcp syns crossing the tun to it
          mtu = 1400;
          endpoints = lib.map (ep: { serial = ep.serial_number; family = ep.address_family; }) host.ranet.endpoints;
          underlay = lib.mkIf isLinux { inherit mark; };
        };
        dial.all = true;
        cap.route = {
          announce = [ ipam4 ipam6 ];
          transit = false;
        };
        cap.table = {
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
