{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  bp = lib.blueprint;
  host = bp.hosts.${config.networking.hostName} or null;
  hasTag = lib.hasTag config.networking.hostName;

  ipam4 = "${host.ipam.ipv4}/32";
  ipam6 = "${host.ipam.ipv6}/128";

  trust = (pkgs.formats.json { }).generate "trust.json" [ pkgs.gravity.registry ];
in
{
  imports = [ inputs.ranet3.darwinModules.ranet3 ];

  config = lib.mkIf (hasTag "ranet3") {
    assertions = [
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
          key = config.sops.secrets.ranet.path;
          inherit trust;
        };
        link = {
          port = bp.ranet.port;
          endpoints = lib.map (ep: { serial = ep.serial_number; family = ep.address_family; }) host.ranet.endpoints;
        };
        dial.all = true;
        cap.route = {
          announce = [ ipam4 ipam6 ];
          transit = false;
        };
        cap.table.addresses = [ ipam4 ipam6 ];
      };
    };
  };
}
