{ lib, ... }:

let
  # option = "";
  option = ''
    # prefer jp local
    bgp_large_community.add((20473, 6009, 2914)); # NTT
    bgp_large_community.add((20473, 6009, 17676)); # SoftBank
    # prepend 1x
    bgp_large_community.add((20473, 6001, 3320)); # DTAG
    # prepend 2x
    bgp_large_community.add((20473, 6002, 701)); # Verizon
    bgp_large_community.add((20473, 6002, 1299)); # Arelion
    bgp_large_community.add((20473, 6002, 6830)); # Liberty Global
    # prepend 3x
    bgp_large_community.add((20473, 6003, 174)); # Cogent
    bgp_large_community.add((20473, 6003, 1221)); # Telstra
    bgp_large_community.add((20473, 6003, 3356)); # Level3
    bgp_large_community.add((20473, 6003, 4826)); # Vocus
    # https://www.homenoc.ad.jp/tech/community/
    # BIGLOBE hauls singapore to osaka on this customer route
    # prepend 1x
    bgp_large_community.add((59105, 1021, 2518)); # BIGLOBE
  '';

  password = lib.router.bird.symbol "PASS_AS64515";

  # vultr's own neighbor address never goes back to it
  export = static: net: {
    filter.body = ''
      if proto != "${static}" then reject;
      if net = ${net} then reject;
      accept;
    '';
  };
in
{
  imports = [ ./homenoc.nix ];

  services.bird.settings = {
    # runs on the static route of every announced prefix outside the experimental space
    function.origin.body = option;

    protocol.bgp = {
      # https://skym.fi/blog/2020/07/vultr-trouble/
      # importing nothing keeps the multihop neighbors reachable without static routes
      vultr4 = {
        from = "upstream4";
        multihop = true;
        inherit password;
        neighbor = { address = "169.254.169.254"; as = 64515; };
        ipv4.export = export "static4" "169.254.169.254/32";
      };
      vultr6 = {
        from = "upstream6";
        multihop = true;
        inherit password;
        neighbor = { address = "2001:19f0:ffff::1"; as = 64515; };
        ipv6.export = export "static6" "2001:19f0:ffff::1/128";
      };

      # see ./homenoc.nix
      # ingress only, the template already imports nothing
      homenoc4 = {
        from = "upstream4";
        source-address = "103.247.181.67";
        neighbor = { address = "103.247.181.66"; as = 59105; };
      };
      homenoc6 = {
        from = "upstream6";
        source-address = "2403:bd80:bbc0:5308::2";
        neighbor = { address = "2403:bd80:bbc0:5308::1"; as = 59105; };
      };
    };
  };
}
