{ lib, inputs, ... }:

{
  imports = [ inputs.self.nixosModules.garnix ];

  networking = {
    defaultGateway = {
      address = "172.31.1.1";
      interface = "enp1s0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp1s0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      enp1s0 = {
        ipv4.addresses = [
          { address = "37.27.181.83"; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = "2a01:4f9:c012:7b3a::1"; prefixLength = 64; }
          { address = "fe80::9400:3ff:fef4:f8b2"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
      };
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:f4:f8:b2", NAME="enp1s0"
  '';

  system.stateVersion = "25.05";
}

