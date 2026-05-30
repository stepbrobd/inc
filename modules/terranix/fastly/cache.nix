{ lib, ... }:

let
  inherit (lib.terranix) tfRef;

  # cache.ysun.co (niks3 read endpoint)
  domain = lib.blueprint.services.cache.domain;

  s3Bucket = "stepbrobd";
  s3Region = "us-east-005";
  s3Host = "${s3Bucket}.s3.${s3Region}.backblazeb2.com";

  # ro b2 key from modules/terranix/b2/default.nix
  accessKeyId = tfRef "b2_application_key.fastly.application_key_id";
  secretKey = tfRef "b2_application_key.fastly.application_key";
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

    # https://git.clan.lol/clan/clan-infra/src/branch/main/modules/terranix/cache-new.nix
    snippet = [
      {
        name = "recv";
        type = "recv";
        # run before the #FASTLY recv boilerplate (which ends in return)
        priority = 50;
        # fastly needs segmented caching to cache objects > ~2GB (large nars)
        # also drop query strings from the cache key
        content = ''
          set req.url = querystring.remove(req.url);
          if (req.url.path == "/") {
            set req.url = "/index.html";
          }
          if (req.url.path ~ "^/nar/") {
            set req.enable_segmented_caching = true;
          }
        '';
      }
      {
        name = "encoding";
        type = "fetch";
        # run after the #FASTLY fetch boilerplate
        priority = 105;
        # niks3 stores narinfo/.ls/realisations/log zstd-compressed
        # but b2 does not surface Content-Encoding on download
        # re-add here so the nix client decompresses
        content = ''
          if (beresp.status == 200 && (req.url.path ~ "\.(narinfo|ls)$" || req.url.path ~ "^/realisations/" || req.url.path ~ "^/log/")) {
            set beresp.http.Content-Encoding = "zstd";
          }
        '';
      }
      {
        name = "scrub";
        type = "fetch";
        # run after the boilerplate
        priority = 108;
        # strip b2/s3 origin request tracking headers
        content = ''
          unset beresp.http.x-amz-request-id;
          unset beresp.http.x-amz-id-2;
        '';
      }
      {
        name = "stream";
        type = "fetch";
        # must run AFTER the boilerplate to override ttl
        priority = 110;
        # stream miss and serve stale
        content = ''
          set beresp.do_stream = true;

          if (req.url.path == "/nix-cache-info") {
            set beresp.ttl = 1h;
            set beresp.grace = 168h;
          }
        '';
      }
      {
        name = "nix"; # convert 403 to 404 for nix
        type = "fetch";
        # run after the boilerplate
        # so the rewritten 404 inherits the 403 "uncacheable" decision
        # i.e. a missing path stays a fresh miss instead of 24h cached 404
        priority = 115;
        content = ''
          if (beresp.status == 403 && req.url.path != "/nix-cache-info") {
            set beresp.status = 404;
          }
        '';
      }
      {
        name = "b2";
        type = "miss";
        priority = 100;
        # https://www.fastly.com/documentation/guides/integrations/non-fastly-services/backblaze-b2-cloud-storage/
        content = ''
          declare local var.b2AccessKey STRING;
          declare local var.b2SecretKey STRING;
          declare local var.b2Bucket STRING;
          declare local var.b2Region STRING;
          declare local var.canonicalHeaders STRING;
          declare local var.signedHeaders STRING;
          declare local var.canonicalRequest STRING;
          declare local var.canonicalQuery STRING;
          declare local var.stringToSign STRING;
          declare local var.dateStamp STRING;
          declare local var.signature STRING;
          declare local var.scope STRING;

          set var.b2AccessKey = "${accessKeyId}";
          set var.b2SecretKey = "${secretKey}";
          set var.b2Bucket = "${s3Bucket}";
          set var.b2Region = "${s3Region}";

          if ((req.method == "GET" || req.method == "HEAD") && !req.backend.is_shield) {
            set bereq.http.x-amz-content-sha256 = digest.hash_sha256("");
            set bereq.http.x-amz-date = strftime({"%Y%m%dT%H%M%SZ"}, now);
            set bereq.http.host = var.b2Bucket ".s3." var.b2Region ".backblazeb2.com";
            set bereq.url = querystring.remove(bereq.url);
            set bereq.url = regsuball(urlencode(urldecode(bereq.url.path)), {"%2F"}, "/");
            set var.dateStamp = strftime({"%Y%m%d"}, now);
            set var.canonicalHeaders = ""
              "host:" bereq.http.host LF
              "x-amz-content-sha256:" bereq.http.x-amz-content-sha256 LF
              "x-amz-date:" bereq.http.x-amz-date LF
            ;
            set var.canonicalQuery = "";
            set var.signedHeaders = "host;x-amz-content-sha256;x-amz-date";
            set var.canonicalRequest = ""
              bereq.method LF
              bereq.url.path LF
              var.canonicalQuery LF
              var.canonicalHeaders LF
              var.signedHeaders LF
              digest.hash_sha256("")
            ;

            set var.scope = var.dateStamp "/" var.b2Region "/s3/aws4_request";

            set var.stringToSign = ""
              "AWS4-HMAC-SHA256" LF
              bereq.http.x-amz-date LF
              var.scope LF
              regsub(digest.hash_sha256(var.canonicalRequest), "^0x", "")
            ;

            set var.signature = digest.awsv4_hmac(
              var.b2SecretKey,
              var.dateStamp,
              var.b2Region,
              "s3",
              var.stringToSign
            );

            set bereq.http.Authorization = "AWS4-HMAC-SHA256 "
              "Credential=" var.b2AccessKey "/" var.scope ", "
              "SignedHeaders=" var.signedHeaders ", "
              "Signature=" + regsub(var.signature, "^0x", "")
            ;

            unset bereq.http.Accept;
            unset bereq.http.Accept-Language;
            unset bereq.http.User-Agent;
            unset bereq.http.Fastly-Client-IP;
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
