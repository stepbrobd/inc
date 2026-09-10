{ modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  services.qemuGuest.enable = true;

  # misaka hands out a /32 for bgp session with the gateway outside any prefix
  # networkd installs dhcp default without onlink causing bird logs "a strange next-hop" on every scan
  # keep dhcp for the address and RA for v6 and install v4 routes here with the flag
  # link scope host route stays because exit script copies default into ranet table without onlink
  systemd.network.networks."10-enp3s0" = {
    matchConfig.Name = "enp3s0";
    networkConfig = { DHCP = "yes"; IPv6PrivacyExtensions = "kernel"; };
    dhcpV4Config = { UseGateway = false; UseRoutes = false; RoutesToDNS = false; RoutesToNTP = false; };
    routes = [
      { Destination = "100.100.0.0/32"; Scope = "link"; }
      { Gateway = "100.100.0.0"; GatewayOnLink = true; }
    ];
  };

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "vmw_pvscsi"
    "xen_blkfront"
  ];

  system.stateVersion = "25.11";
}
