{
  services.bird.settings.protocol.bgp = {
    netactuate4 = {
      from = "upstream4";
      neighbor = { address = "45.159.98.175"; as = 36236; };
    };
    netactuate6 = {
      from = "upstream6";
      neighbor = { address = "2a00:dd80:40:100::312"; as = 36236; };
    };
  };
}
