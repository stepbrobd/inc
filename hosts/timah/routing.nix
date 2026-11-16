let
  # option = "";
  # https://docs.misaka.io/network/communities
  # (rt, 65009, ASN) dont announce, (rt, 65001-65003, ASN) prepend Nx
  # GSL is the transit and hauls its whole footprint to a customer route
  # if needed (rt, 65009, 13335) cloudflare returns non EU traffic via here
  option = ''
    bgp_ext_community.add((rt, 65009, 137409)); # dont announce to GSL
  '';
in
{
  services.bird.settings = {
    # runs on the static route of every announced prefix outside the experimental space
    function.origin.body = option;

    protocol.bgp = {
      misaka4 = {
        from = "upstream4";
        multihop = true;
        neighbor = { address = "100.100.0.0"; as = 57695; };
      };
      misaka6 = {
        from = "upstream6";
        multihop = true;
        neighbor = { address = "2a0b:4342:ffff::"; as = 57695; };
      };
    };
  };
}
