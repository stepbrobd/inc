let
  option = "";
  # option = ''
  #   bgp_large_community.add((21700, 101, 2)); # customer route
  #   bgp_large_community.add((21700, 102, 840)); # source US
  #   bgp_large_community.add((21700, 103, 1)); # source NYC
  # '';
in
{
  services.bird.settings = {
    # runs on the static route of every announced prefix outside the experimental space
    function.origin.body = option;

    protocol.bgp = {
      neptune4 = {
        from = "upstream4";
        neighbor = { address = "172.82.22.129"; as = 21700; };
      };
      neptune6 = {
        from = "upstream6";
        multihop = true;
        neighbor = { address = "2602:fe2e:4:80::1"; as = 21700; };
      };
    };
  };
}
