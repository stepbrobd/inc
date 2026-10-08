{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.networking.ranet3;
  bp = lib.blueprint;
  host = bp.hosts.${config.networking.hostName} or null;
  hasTag = lib.hasTag config.networking.hostName;

  table = 200;
  # SO_MARK on the underlay socket
  # priority 40 rule keeps it in main
  # exit announced default never carries the tunnel inside itself
  mark = 29292; # 0x726c
  # 1400 byte tun - 40 ipv6 - 20 tcp - 12 timestamps
  # see as10779 module clamp value
  # holds only while no cap.segment.steer shrinks the tun
  mss = 1328;

  ipam4 = "${host.ipam.ipv4}/32";
  ipam6 = "${host.ipam.ipv6}/128";

  # my own nodes only
  trust = (pkgs.formats.json { }).generate "trust.json" [ pkgs.gravity.registry ];
in
{
  imports = [ inputs.ranet3.nixosModules.ranet3 ];

  # currently keep this leaf only
  config = lib.mkIf (hasTag "ranet3") {
    assertions = [
      {
        assertion = !(config.networking.ranet.enable or false);
        message = "ranet3 and ranet both bind udp ${toString bp.ranet.port}, tag a host with one of them";
      }
      {
        assertion = host != null && host.type != "server" && host.ipam ? ipv4 && host.ipam ? ipv6 && host.ranet ? endpoints;
        message = "ranet3 needs a non-server blueprint host with ipam.ipv4, ipam.ipv6 and ranet.endpoints";
      }
    ];

    sops.secrets.ranet = {
      mode = "600";
      restartUnits = [ config.systemd.services.ranet3.name ];
    };

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
          port = bp.ranet.port;
          endpoints = lib.map (ep: { serial = ep.serial_number; family = ep.address_family; }) host.ranet.endpoints;
          underlay.mark = mark;
        };
        dial.all = true;
        cap.route = {
          announce = [ ipam4 ipam6 ];
          transit = false;
        };
        cap.table = {
          id = table;
          addresses = [ ipam4 ipam6 ];
          rules = [
            { fwmark = mark; table = "main"; priority = 40; family = "both"; }
          ]
          ++ lib.map (to: { inherit to table; priority = 100; }) bp.net.gravity.ipv6
          ++ lib.map (from: { inherit from table; priority = 150; }) [ ipam4 ipam6 ];
        };
      };
    };

    users.users.ysun.extraGroups = [ cfg.group ];

    # networkd drops rules that did not request on resume/restart
    systemd.network.config.networkConfig = {
      ManageForeignRoutingPolicyRules = lib.mkDefault false;
      ManageForeignRoutes = lib.mkDefault false;
    };

    networking.nftables.tables.ranet3 = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority mangle; policy accept;
          tcp flags & syn == syn ip saddr ${host.ipam.ipv4} tcp option maxseg size gt ${toString mss} tcp option maxseg size set ${toString mss}
          tcp flags & syn == syn ip6 saddr ${host.ipam.ipv6} tcp option maxseg size gt ${toString mss} tcp option maxseg size set ${toString mss}
        }
      '';
    };
  };
}
