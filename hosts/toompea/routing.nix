{ config, lib, pkgs, ... }:

let
  inherit (config.services.bird.settings.protocol) static;

  # option = "";
  # 3204:XXXx per whois AS3204 remarks, x = 1-3 prepend Nx, x = 0 dont announce
  # 100x Telia, 110x xTom, 170x Liberty Global, 190x Tata, others are IXes
  # telia and tata haul their whole footprint to a customer route
  # if needed (3204, 1101) prepend 1x toward xTom to shrink the IX pull
  option = ''
    bgp_community.add((3204, 1000)); # dont announce to Telia
    bgp_community.add((3204, 1900)); # dont announce to Tata
  '';

  password = lib.router.bird.symbol "PASS_AS3204";

  # upstream bgp gateway differs from main interface gateway
  # only because the upstream provider requires it
  gateway = {
    ipv4 = "185.194.53.4";
    ipv6 = "2a04:6f00:4::4";
  };
  table = 10779;
in
{
  services.bird.settings = {
    # runs on the static route of every announced prefix outside the experimental space
    function.origin.body = option;

    protocol.bgp = {
      xtom4 = {
        from = "upstream4";
        inherit password;
        neighbor = { address = gateway.ipv4; as = 3204; };
        ipv4.import = "all";
      };
      xtom6 = {
        from = "upstream6";
        inherit password;
        neighbor = { address = gateway.ipv6; as = 3204; };
        ipv6.import = "all";
      };
      bgptools6 = {
        from = "upstream6";
        multihop = true;
        neighbor = { address = "2a0c:2f07:9459::b19"; as = 212232; };
        ipv6.export = "all";
        # bgp.tools also collects ipv4 over the ipv6 session, with the uplink's ipv4 as next hop
        ipv4 = {
          import = "none";
          export = "all";
          next-hop-address = lib.blueprint.hosts.toompea.ipv4;
        };
      };
    };
  };

  # the announced space leaves by the bgp gateway
  systemd.network.networks."40-${lib.blueprint.hosts.toompea.ipam.interface}".routingPolicyRules = lib.concatMap
    (protocol: lib.map (route: { From = route.prefix; Table = table; Priority = 10000; }) protocol.route)
    [ static.static4 static.static6 ];

  services.networkd-dispatcher.rules."40-gravity-routes" = {
    onState = [ "routable" ];
    script = ''
      #!${pkgs.runtimeShell}

      export PATH=${lib.makeBinPath (with pkgs; [ coreutils iproute2 ])}

      ip -4 route replace default via ${gateway.ipv4} table ${toString table}
      ip -6 route replace default via ${gateway.ipv6} table ${toString table}
    '';
  };
}
