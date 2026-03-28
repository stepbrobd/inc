{
  time.timeZone = "Europe/Paris";

  networking = {
    hostName = "macbook";
    localHostName = "Yifeis-MacBook";
    computerName = "Yifei's MacBook";
    knownNetworkServices = [
      "Tailscale Tunnel"
      "Wi-Fi"
      "Bluetooth PAN"
      "iPhone USB"
      "Ethernet Adaptor"
      "Belkin USB-C LAN"
      "USB 10/100/1000 LAN"
      "Thunderbolt Bridge"
      "Thunderbolt Ethernet Slot 1"
      "Thunderbolt Ethernet Slot 2"
      "Thunderbolt Ethernet Slot 3"
      "Thunderbolt Ethernet Slot 4"
    ];
  };

  # nix.nixbuild.enable = true;
  system.stateVersion = 5;
}
