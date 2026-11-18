{
  services.bird.settings.protocol.bgp = {
    netactuate4 = {
      from = "upstream4";
      neighbor = { address = "103.6.84.13"; as = 36236; };
      ipv4.gateway = "recursive";
    };
    netactuate6 = {
      from = "upstream6";
      neighbor = { address = "2403:2500:8000:1::5ea"; as = 36236; };
    };
  };
}
