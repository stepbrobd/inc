{ lib, ... }:

let
  # both virtua routers take the same password over multihop
  virtua = upstream: {
    from = upstream;
    multihop = true;
    authentication = "md5";
    password = lib.router.bird.symbol "PASS_AS35661";
  };
in
{
  services.bird.settings = {
    template.bgp = {
      virtua4 = virtua "upstream4";
      virtua6 = virtua "upstream6";
    };

    protocol.bgp = {
      virtua14 = {
        from = "virtua4";
        neighbor = { address = "172.16.0.121"; as = 35661; };
      };
      virtua16 = {
        from = "virtua6";
        neighbor = { address = "2a0d:e680:0::b:1"; as = 35661; };
      };
      virtua24 = {
        from = "virtua4";
        neighbor = { address = "172.16.0.122"; as = 35661; };
      };
      virtua26 = {
        from = "virtua6";
        neighbor = { address = "2a0d:e680:0::b:2"; as = 35661; };
      };
    };
  };
}
