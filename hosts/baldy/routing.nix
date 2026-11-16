{
  services.bird.settings.protocol.bgp = {
    netactuate4 = {
      from = "upstream4";
      neighbor = { address = "208.111.40.100"; as = 36236; };
    };
    netactuate6 = {
      from = "upstream6";
      neighbor = { address = "2607:f740:c::6cf"; as = 36236; };
    };
  };
}
