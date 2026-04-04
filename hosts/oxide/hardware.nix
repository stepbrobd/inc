{ config, modulesPath, ... }:

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

  # route64 wg tunnel for public ipv6
  # oxide NAT doesn't forward sit
  networking.ranet.interfaces = [ "wg0" "enp0s8" ];

  # oxide is like aws they 1-1 NAT the public ip
  # null the local address so strongswan resolves source via routing table
  # the registry still advertises public IP for peers to connect to just like isere
  # networking.ranet.settings.endpoints = lib.map
  #   (ep: if ep.address_family == "ip4" then ep // { address = null; } else ep)
  #   lib.blueprint.hosts.oxide.ranet.endpoints;

  # systemd.services.strongswan-swanctl.after = [ "systemd-networkd.service" ];
  # systemd.services.strongswan-swanctl.wants = [ "systemd-networkd.service" ];

  sops.secrets.wg0 = {
    sopsFile = ./secrets.yaml;
    mode = "440";
    group = "systemd-network";
  };

  systemd.network.netdevs."30-wg0" = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "wg0";
    };
    wireguardConfig.PrivateKeyFile = config.sops.secrets.wg0.path;
    wireguardPeers = [{
      PublicKey = "k8u2uzVnJZz429l8Yrpd+XJvaV3VJLdEBQzmeCa3Wnw=";
      AllowedIPs = [ "::/1" "8000::/1" ];
      Endpoint = "23.154.8.27:20003";
      PersistentKeepalive = 15;
    }];
  };

  systemd.network.networks."30-wg0" = {
    name = "wg0";
    address = [ "2a11:6c7:f33:41::2/64" ];
    routes = [
      { Destination = "::/1"; }
      { Destination = "8000::/1"; }
    ];
    linkConfig.RequiredForOnline = false;
  };

  system.stateVersion = "26.05";
}
