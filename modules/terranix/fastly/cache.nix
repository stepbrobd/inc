{ lib, ... }:

let
  inherit (lib.terranix) tfRef;

  # cache.ysun.co (niks3 read endpoint)
  domain = lib.blueprint.services.cache.domain;

  s3Bucket = "stepbrobd";
  s3Region = "us-east-005";
  s3Host = "${s3Bucket}.s3.${s3Region}.backblazeb2.com";
in
{
  resource.fastly_service_vcl.cache = {
    name = domain;
    # fallback ttl
    # b2 should set immutable cache-control on nix objects
    default_ttl = 86400;

    domain = [{
      name = domain;
      comment = "Nix Binary Cache";
    }];

    backend = [{
      name = "s3";
      address = s3Host;
      override_host = s3Host;
      ssl_cert_hostname = s3Host;
      ssl_sni_hostname = s3Host;
      port = 443;
      use_ssl = true;
      ssl_check_cert = true;
      auto_loadbalance = false;
      weight = 100;
      between_bytes_timeout = 10000;
      connect_timeout = 5000;
      first_byte_timeout = 15000;
      max_conn = 200;
      error_threshold = 0;
    }];

    request_setting = [{
      name = "force-ssl";
      force_ssl = true;
    }];

    snippet = [
      {
        name = "recv";
        type = "recv";
        priority = 100;
        # fastly needs segmented caching to cache objects > ~2GB (large nars)
        content = ''
          if (req.url.path ~ "^/nar/") {
            set req.enable_segmented_caching = true;
          }
        '';
      }
      {
        name = "fetch";
        type = "fetch";
        priority = 100;
        # niks3 stores narinfo/.ls/realisations/log zstd-compressed
        # but b2 does not surface Content-Encoding on download
        # re-add here so the nix client decompresses
        content = ''
          if (beresp.status == 200 && (req.url.path ~ "\.(narinfo|ls)$" || req.url.path ~ "^/realisations/" || req.url.path ~ "^/log/")) {
            set beresp.http.Content-Encoding = "zstd";
          }
        '';
      }
    ];
  };

  resource.fastly_tls_subscription.cache = {
    domains = [ domain ];
    certificate_authority = "lets-encrypt";
  };

  resource.fastly_tls_subscription_validation.cache = {
    subscription_id = tfRef "fastly_tls_subscription.cache.id";
    depends_on = [ "cloudflare_dns_record.co_ysun_cache_acme" ];
  };

  data.fastly_tls_configuration.cache = {
    default = true;
    depends_on = [ "fastly_tls_subscription_validation.cache" ];
  };

  resource.cloudflare_dns_record.co_ysun_cache_acme = lib.terranix.mkRecord "ysun.co" {
    type = tfRef ''one(fastly_tls_subscription.cache.managed_dns_challenges).record_type'';
    name = tfRef ''trimsuffix(one(fastly_tls_subscription.cache.managed_dns_challenges).record_name, ".ysun.co")'';
    content = tfRef ''one(fastly_tls_subscription.cache.managed_dns_challenges).record_value'';
    proxied = false;
    comment = "Fastly - ACME for Nix Binary Cache (niks3 @ cache.ysun.co)";
  };

  resource.cloudflare_dns_record.co_ysun_cache = lib.terranix.mkRecord "ysun.co" {
    type = "CNAME";
    name = "cache";
    content = tfRef ''format("dualstack.%s", one([for r in data.fastly_tls_configuration.cache.dns_records : r.record_value if r.record_type == "CNAME"]))'';
    proxied = false;
    comment = "Fastly - Nix Binary Cache (niks3 @ cache.ysun.co)";
  };
}
