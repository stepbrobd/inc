{ lib, ... }:

let
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
  services.bird.settings.protocol.bgp = {
    vultr4 = {
      from = "upstream4";
      multihop = true;
      authentication = "md5";
      inherit password;
      neighbor = { address = "169.254.169.254"; as = 64515; };
      ipv4.export = export "static4" "169.254.169.254/32";
    };
    vultr6 = {
      from = "upstream6";
      multihop = true;
      authentication = "md5";
      inherit password;
      neighbor = { address = "2001:19f0:ffff::1"; as = 64515; };
      ipv6.export = export "static6" "2001:19f0:ffff::1/128";
    };
  };
}
