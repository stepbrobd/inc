{ lib, ... } @ args:

{ ... }:

let
  inherit (lib) map filter attrNames readDir filterAttrs mapAttrsToList splitString toInt;
  inherit (lib.terranix) acnsSettings;

  # only for ipv4, do we need to upstream this?
  compareIPs = a: b: map toInt (splitString "." a) < map toInt (splitString "." b);
in
{
  imports = map
    (f: import ./${f} args)
    (filter
      (f: f != "default.nix")
      (attrNames (readDir ./.)));

  # NOTE:
  # account singleton
  # a destroy here would delete the account
  resource.cloudflare_account.stepbrobd = {
    lifecycle.prevent_destroy = true;
    name = "StepBroBD, Inc.";
    settings = {
      abuse_contact_email = "noc@stepbrobd.com";
      enforce_twofactor = true;
    };
  };

  resource.cloudflare_account_dns_settings.settings = acnsSettings;

  resource.cloudflare_magic_network_monitoring_configuration.mnm = {
    account_id = ''''${data.sops_file.secrets.data["cloudflare.account_id"]}'';
    name = "StepBroBD";
    # should match prometheus module rfm sample_rate
    default_sampling = 10;
    # IPs from which RFM sends IPFIX flow data (must match prometheus module's ipfix.bind.host)
    router_ips = lib.sort compareIPs (mapAttrsToList
      (_: host: host.ipam.ipv4 or host.ipv4)
      (filterAttrs (_: host: host ? interface && host.interface != null) lib.blueprint.hosts));
    warp_devices = [ ];
  };
}
