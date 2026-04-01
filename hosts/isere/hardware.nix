{ inputs, lib, ... }:

{
  imports = with inputs.rpi.nixosModules; [
    ./disko.nix
    inputs.disko.nixosModules.disko

    nixpkgs-rpi
    inputs.rpi.lib.inject-overlays

    raspberry-pi-5.base
    raspberry-pi-5.bluetooth
    raspberry-pi-5.display-vc4
  ];

  # they added this weird ass requirement but i dont wanna
  # https://github.com/nvmd/nixos-raspberrypi/pull/156
  # that means i need to either dont change rpi in inputs
  # or remember to change it here as well...
  _module.args.nixos-raspberrypi = inputs.rpi;

  boot.loader.raspberry-pi.bootloader = "kernel";

  # bluetooth
  # https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5#Bluetooth
  boot.kernelModules = [
    "hci_uart"
    "btbcm"
    "bluetooth"
    "btsdio"
    "brcmfmac"
  ];

  # https://github.com/nvmd/nixos-raspberrypi-demo/blob/2847963e7555fc412c1d0f37bb48c761e78f350d/flake.nix#L154-L160
  # Ignore partitions with "Required Partition" GPT partition attribute
  # On our RPis this is firmware (/boot/firmware) partition
  services.udev.extraRules = ''
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

  # https://github.com/nvmd/nixos-raspberrypi-demo/blob/2847963e7555fc412c1d0f37bb48c761e78f350d/pi5-configtxt.nix
  hardware.raspberry-pi.config = {
    all = {
      dt-overlays.miniuart-bt = {
        enable = true;
        params = { };
      };

      base-dt-params = {
        pciex1 = {
          enable = true;
          value = "on";
        };
        pciex1_gen = {
          enable = true;
          value = "3";
        };

        fan_temp0 = {
          enable = true;
          value = 40000; # 40c
        };
        fan_temp0_hyst = {
          enable = true;
          value = 10000;
        };
        fan_temp0_speed = {
          enable = true;
          value = 135;
        };

        fan_temp1 = {
          enable = true;
          value = 45000; # 45c
        };
        fan_temp1_hyst = {
          enable = true;
          value = 5000;
        };
        fan_temp1_speed = {
          enable = true;
          value = 175;
        };

        fan_temp2 = {
          enable = true;
          value = 50000; # 50c
        };
        fan_temp2_hyst = {
          enable = true;
          value = 5000;
        };
        fan_temp2_speed = {
          enable = true;
          value = 215;
        };

        fan_temp3 = {
          enable = true;
          value = 55000; # 55c
        };
        fan_temp3_hyst = {
          enable = true;
          value = 5000;
        };
        fan_temp3_speed = {
          enable = true;
          value = 255;
        };
      };
    };
  };

  # HE tunnel broker (6in4) for public IPv6
  # end0 needed for IPv4 IKE
  networking.ranet.interfaces = [ "he0" "end0" ];

  # ISP DMZ NAT
  # public IPv4 (88.140.186.193) is not on end0
  # so null the local address so strongswan resolves source via routing table
  # the registry still advertises public IP for peers to connect to
  networking.ranet.settings.endpoints = lib.map
    (ep: if ep.address_family == "ip4" then ep // { address = null; } else ep)
    lib.blueprint.hosts.isere.ranet.endpoints;

  systemd.services.strongswan-swanctl.after = [ "systemd-networkd.service" ];
  systemd.services.strongswan-swanctl.wants = [ "systemd-networkd.service" ];

  systemd.network.netdevs."30-he0" = {
    netdevConfig = {
      Kind = "sit";
      Name = "he0";
    };
    tunnelConfig = {
      Remote = "216.66.84.42";
      TTL = 255;
      Independent = true;
    };
  };

  systemd.network.networks."30-he0" = {
    name = "he0";
    address = [ "2001:470:1f12:441::2/64" ];
    routes = [{ Gateway = "2001:470:1f12:441::1"; }];
    linkConfig.RequiredForOnline = false;
  };

  system.stateVersion = "25.05";
}
