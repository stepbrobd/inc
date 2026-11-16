{
  services.bird.settings.protocol.bgp = {
    netactuate4 = {
      from = "upstream4";
      neighbor = { address = "148.163.220.95"; as = 36236; };
    };
    netactuate6 = {
      from = "upstream6";
      neighbor = { address = "2607:f740:1::e37"; as = 36236; };
    };
  };
}
