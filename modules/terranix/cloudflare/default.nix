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

  resource.cloudflare_zero_trust_access_identity_provider.idp = {
    account_id = ''''${data.sops_file.secrets.data["cloudflare.account_id"]}'';
    name = "OpenID Connect";
    type = "oidc";

    # oidc config
    config = {
      client_id = ''''${data.sops_file.secrets.data["cloudflare.sso_client_id"]}'';
      client_secret = ''''${data.sops_file.secrets.data["cloudflare.sso_client_secret"]}'';

      auth_url = "https://sso.ysun.co/ui/oauth2";
      token_url = "https://sso.ysun.co/oauth2/token";
      certs_url = "https://sso.ysun.co/oauth2/openid/cloudflare/public_key.jwk";

      pkce_enabled = true;

      scopes = [
        "openid"
        "email"
        "profile"
      ];
    };

    # kanidm have no support for scim yet
    scim_config = rec {
      enabled = false;
      user_deprovision = enabled;
      seat_deprovision = enabled;
      group_member_deprovision = enabled;
      identity_update_behavior = "automatic";
    };
  };
}
