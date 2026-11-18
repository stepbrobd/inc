{
  services.bird.settings.protocol.bgp = {
    netactuate4 = {
      from = "upstream4";
      neighbor = { address = "43.245.48.221"; as = 36236; };
      ipv4.gateway = "recursive";
    };
    netactuate6 = {
      from = "upstream6";
      neighbor = { address = "2403:2500:9000:1::46e"; as = 36236; };
    };
  };
}
