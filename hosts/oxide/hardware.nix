{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
  services.qemuGuest.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
  ];

  # HE tunnel broker (6in4) for public IPv6
  # end0 needed for IPv4 IKE
  networking.ranet.interfaces = [ "he0" "enp0s8" ];

  # oxide is like aws they 1-1 NAT the public ip
  # null the local address so strongswan resolves source via routing table
  # the registry still advertises public IP for peers to connect to just like isere
  # networking.ranet.settings.endpoints = lib.map
  #   (ep: if ep.address_family == "ip4" then ep // { address = null; } else ep)
  #   lib.blueprint.hosts.oxide.ranet.endpoints;

  # systemd.services.strongswan-swanctl.after = [ "systemd-networkd.service" ];
  # systemd.services.strongswan-swanctl.wants = [ "systemd-networkd.service" ];

  systemd.network.netdevs."30-he0" = {
    netdevConfig = {
      Kind = "sit";
      Name = "he0";
    };
    tunnelConfig = {
      Remote = "72.52.104.74";
      TTL = 255;
      Independent = true;
    };
  };

  systemd.network.networks."30-he0" = {
    name = "he0";
    address = [ "2001:470:1f04:460::2/64" ];
    routes = [{ Gateway = "2001:470:1f04:460::1/64"; }];
    linkConfig.RequiredForOnline = false;
  };

  system.stateVersion = "26.05";
}
