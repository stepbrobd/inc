{ newHost, ... }:

newHost {
  name = "Noches";
  hostName = "noches";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "owned";
  providerName = "HPE ProLiant DL380 Gen 10";
  type = "server";
  tags = [ ]; # retag CI after moving this into colo
  meta = { city = "Grenoble"; region = "FR-ARA"; country = "FR"; continent = "Europe"; postal = "38000"; };
}
