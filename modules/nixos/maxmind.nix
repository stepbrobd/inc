{ lib, ... }:

{ config, ... }:

{
  sops.secrets."maxmind/license" = { };

  services.geoipupdate = {
    settings = {
      DatabaseDirectory = "/var/lib/maxmind";

      AccountID = 953733;
      LicenseKey._secret = config.sops.secrets."maxmind/license".path;

      EditionIDs = [ "GeoLite2-ASN" "GeoLite2-City" ];
    };
  };

  systemd.timers = lib.mkIf config.services.geoipupdate.enable {
    geoipupdate.timerConfig = {
      RandomizedDelaySec = "6d";
      FixedRandomDelay = true;
    };
  };
}
