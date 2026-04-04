{ lib }:

let
  # cloudflare common ACNS settings
  acns = {
    nameservers = {
      type = "custom.account";
      ns_set = 1;
    };
    foundation_dns = false;
    multi_provider = false;
    secondary_overrides = false;
    soa = {
      mname = "dns.ysun.co";
      rname = "noc.ysun.co";
      refresh = 10000;
      retry = 2400;
      expire = 604800;
      min_ttl = 1800;
      ttl = 3600;
    };
    ns_ttl = 86400;
    zone_mode = "standard";
    flatten_all_cnames = false;
    internal_dns = { };
  };
in
rec {
  # default settings for terraform block
  terraform = {
    backend = rec {
      r2 = s3;
      s3 = {
        terraform.backend.s3 = {
          region = "auto";
          bucket = "terraform";
          key = "github.com/stepbrobd/inc/terraform.tfstate";
          endpoints.s3 = "https://6ff6fca6d9ffe9c77dd15a9095076b3b.eu.r2.cloudflarestorage.com";
          encrypt = true;
          use_lockfile = true;
          skip_credentials_validation = true;
          skip_metadata_api_check = true;
          skip_region_validation = true;
          skip_requesting_account_id = true;
          skip_s3_checksum = true;
          use_path_style = true;
        };
      };
    };
  };

  # default settings for provider block
  provider = {
    cloudflare = {
      terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";
      provider.cloudflare = {
        email = ''''${data.sops_file.secrets.data["cloudflare.email"]}'';
        api_key = ''''${data.sops_file.secrets.data["cloudflare.api_key"]}'';
      };
    };

    sops = {
      terraform.required_providers.sops.source = "carlpett/sops";
      provider.sops = { };
      data.sops_file.secrets.source_file = lib.toString ./secrets.yaml;
    };

    tailscale = {
      terraform.required_providers.tailscale.source = "tailscale/tailscale";
      provider.tailscale = {
        tailnet = ''''${data.sops_file.secrets.data["tailscale.tailnet"]}'';
        oauth_client_id = ''''${data.sops_file.secrets.data["tailscale.client_id"]}'';
        oauth_client_secret = ''''${data.sops_file.secrets.data["tailscale.client_secret"]}'';
      };
    };
  };

  # helper functions
  tfRef = ref: "\${${ref}}";

  # cf r2 helper
  mkBucket = config: {
    account_id = ''''${data.sops_file.secrets.data["cloudflare.account_id"]}'';
  } // config;

  # cf dns helper
  mkZone = config: {
    account.id = ''''${data.sops_file.secrets.data["cloudflare.account_id"]}'';
    type = "full";
    paused = false;
    # for some reason only works with enterprise zones
    # even though ACNS is enabled
    # vanity_name_servers = [
    #   "dns.ysun.co"
    #   "mom.ysun.co"
    #   "dad.ysun.co"
    # ];
  } // config;
  acnsSettings = {
    account_id = ''''${data.sops_file.secrets.data["cloudflare.account_id"]}'';
  } // { zone_defaults = acns; };
  mkZoneSettings = zone: {
    zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
  } // acns;
  forZone = zone: lib.mapAttrs (_: record: mkRecord zone record);
  mkRecord =
    zone: record: {
      zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
      ttl = 1;
    } // record;
  mkPersonalSiteRebind =
    overrides: {
      type = "CNAME";
      proxied = false;
      content = "ysun.co";
      comment = "CNAME Rebind - Personal Site";
    } // overrides;

  # cf helpers for adding purelymail records
  mkPurelyMailRecord =
    let
      comment = "Purelymail - Custom Domain";
      ownership = ''"purelymail_ownership_proof=1559fbc37e4cd506bdc8f5737c3f951d0229b1b32c0d72b38d11f40fc9b00676d25a724c5904a7ba1440d46529b3ac8b5101208d5d96a01d2941ed1bd77ed7df"'';
    in
    zone: prefix: forZone zone {
      "${prefix}_purelymail_mx" = {
        inherit comment;
        type = "MX";
        proxied = false;
        name = "@";
        content = "mailserver.purelymail.com";
        priority = 10;
      };
      "${prefix}_purelymail_spf" = {
        inherit comment;
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"v=spf1 include:_spf.purelymail.com ~all"'';
      };
      "${prefix}_purelymail_ownership" = {
        inherit comment;
        type = "TXT";
        proxied = false;
        name = "@";
        content = ownership;
      };
      "${prefix}_purelymail_dkim1" = {
        inherit comment;
        type = "CNAME";
        proxied = false;
        name = "purelymail1._domainkey";
        content = "key1.dkimroot.purelymail.com";
      };
      "${prefix}_purelymail_dkim2" = {
        inherit comment;
        type = "CNAME";
        proxied = false;
        name = "purelymail2._domainkey";
        content = "key2.dkimroot.purelymail.com";
      };
      "${prefix}_purelymail_dkim3" = {
        inherit comment;
        type = "CNAME";
        proxied = false;
        name = "purelymail3._domainkey";
        content = "key3.dkimroot.purelymail.com";
      };
      "${prefix}_purelymail_dmarc" = {
        inherit comment;
        type = "CNAME";
        proxied = false;
        name = "_dmarc";
        content = "dmarcroot.purelymail.com";
      };
    };

  # tailscale device data helper
  mkDevices = devices: lib.listToAttrs
    (lib.map
      (d: {
        name = d;
        value = {
          # apparently for some hosts using hostname won't work
          # fix for this is `tailscale set --hostname <hostname>` on the device
          # or switch to using fqdn (but hostname/name are mutually exclusive)
          # hostname = d;
          name = ''${d}.''${data.sops_file.secrets.data["tailscale.tailnet_name"]}'';
          wait_for = "10s";
        };
      })
      devices);
}
