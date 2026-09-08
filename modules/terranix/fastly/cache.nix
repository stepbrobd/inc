{ lib, ... }:

let
  inherit (lib.terranix) tfRef;

  # cache.ysun.co (niks3 read endpoint)
  domain = lib.blueprint.services.cache.domain;

  # fastly object storage (path style) bucket declared below
  s3Bucket = "cache";
  s3Region = "us-east-1";
  s3Host = "${s3Region}.object.fastlystorage.app";
  # ro key scoped to the storage backend declared below
  accessKeyId = tfRef "fastly_object_storage_access_keys.cache.access_key_id";
  secretKey = tfRef "fastly_object_storage_access_keys.cache.secret_key";
in
{
  resource.fastly_service_vcl.cache = {
    name = "Cache";
    default_ttl = 3600;

    http3 = true;

    product_enablement = [{
      name = "cache";
      origin_inspector = true;
      domain_inspector = true;
      log_explorer_insights = true;
      ngwaf = [{
        enabled = false;
        workspace_id = tfRef "fastly_ngwaf_workspace.ngwaf.id";
      }];
      # ddos_protection = [{
      #   enabled = true;
      #   mode = "log";
      # }];
    }];

    backend = [{
      name = "s3";
      address = s3Host;

      shield = "iad-va-us";

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
      max_conn = 250;
      error_threshold = 0;
    }];

    request_setting = [{
      name = "force-ssl";
      force_ssl = true;
    }];

    # see modules/nixos/caddy.nix
    header = [{
      name = "hsts";
      action = "set";
      type = "response";
      destination = "http.Strict-Transport-Security";
      source = ''"max-age=31536000; includeSubDomains; preload"'';
      ignore_if_set = false;
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

          if (req.url.path == "/" || req.url.path == "/index.html") {
            set req.http.X-Redirect-To = "https://ysun.co/setup/";
            error 618;
          }
          if (req.url.path == "/favicon.ico") {
            set req.http.X-Redirect-To = "https://ysun.co/favicon.ico";
            error 618;
          }

          if (req.url.path ~ "^/nar/") {
            set req.enable_segmented_caching = true;
          }
        '';
      }
      {
        name = "redirect";
        type = "error";
        # run before the #FASTLY error boilerplate
        priority = 50;
        # https://www.fastly.com/documentation/solutions/tutorials/custom-vcl/redirects/
        content = ''
          if (obj.status == 618) {
            set obj.http.Location = req.http.X-Redirect-To;
            set obj.status = 301;
            set obj.response = "Moved Permanently";
            synthetic "";
            return(deliver);
          }
        '';
      }
      {
        name = "encoding";
        type = "fetch";
        # run after the #FASTLY fetch boilerplate
        priority = 105;
        content = ''
          if (beresp.status == 200 && (req.url.path ~ "\.(narinfo|ls)$" || req.url.path ~ "^/realisations/" || req.url.path ~ "^/log/")) {
            set beresp.http.Content-Encoding = "zstd";
          }
        '';
      }
      {
        name = "scrub";
        type = "fetch";
        # run after encoding (105) to make sure Content-Encoding header is not dropped
        priority = 108;
        # use allow list for headers
        content = ''
          header.filter_except(beresp,
            "Accept-Ranges",
            "Age",
            "Cache-Control",
            "Content-Encoding",
            "Content-Length",
            "Content-Range",
            "Content-Type",
            "Date",
            "ETag",
            "Last-Modified",
            "Via",
            "X-Cache",
            "X-Cache-Hits",
            "X-Served-By"
          );
        '';
      }
      {
        name = "stream";
        type = "fetch";
        # must run AFTER the boilerplate to override ttl
        priority = 110;
        # stream miss and serve stale with 1yr ttl on immutable paths
        content = ''
          set beresp.do_stream = true;

          if (req.url.path == "/nix-cache-info") {
            set beresp.ttl = 1h;
          } else if ((beresp.status == 200 || beresp.status == 206) && (req.url.path ~ "^/nar/" || req.url.path ~ "\.(narinfo|ls)$" || req.url.path ~ "^/(log|realisations)/")) {
            set beresp.ttl = 365d;
            set beresp.http.Cache-Control = "public, max-age=31536000, immutable";
          }

          set beresp.stale_if_error = 168h;
        '';
      }
      {
        name = "negative";
        type = "fetch";
        # run after stream to override ttl/cacheable decisions
        priority = 115;
        content = ''
          if (beresp.status == 404 && (req.url.path ~ "\.narinfo$" || req.url.path ~ "^/realisations/")) {
            set beresp.cacheable = true;
            set beresp.ttl = 60s;
            set beresp.http.Cache-Control = "public, max-age=60";
          }
        '';
      }
      {
        name = "s3";
        type = "miss";
        priority = 100;
        # sigv4 https://www.fastly.com/documentation/guides/integrations/non-fastly-services/amazon-s3/
        content = ''
          declare local var.s3AccessKey STRING;
          declare local var.s3SecretKey STRING;
          declare local var.s3Bucket STRING;
          declare local var.s3Region STRING;
          declare local var.canonicalHeaders STRING;
          declare local var.signedHeaders STRING;
          declare local var.canonicalRequest STRING;
          declare local var.canonicalQuery STRING;
          declare local var.stringToSign STRING;
          declare local var.dateStamp STRING;
          declare local var.signature STRING;
          declare local var.scope STRING;

          set var.s3AccessKey = "${accessKeyId}";
          set var.s3SecretKey = "${secretKey}";
          set var.s3Bucket = "${s3Bucket}";
          set var.s3Region = "${s3Region}";

          if ((req.method == "GET" || req.method == "HEAD") && !req.backend.is_shield) {
            set bereq.http.x-amz-content-sha256 = digest.hash_sha256("");
            set bereq.http.x-amz-date = strftime({"%Y%m%dT%H%M%SZ"}, now);
            set bereq.http.host = "${s3Host}";
            set bereq.url = querystring.remove(bereq.url);
            set bereq.url = "/" var.s3Bucket regsuball(urlencode(urldecode(bereq.url.path)), {"%2F"}, "/");
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

            set var.scope = var.dateStamp "/" var.s3Region "/s3/aws4_request";

            set var.stringToSign = ""
              "AWS4-HMAC-SHA256" LF
              bereq.http.x-amz-date LF
              var.scope LF
              regsub(digest.hash_sha256(var.canonicalRequest), "^0x", "")
            ;

            set var.signature = digest.awsv4_hmac(
              var.s3SecretKey,
              var.dateStamp,
              var.s3Region,
              "s3",
              var.stringToSign
            );

            set bereq.http.Authorization = "AWS4-HMAC-SHA256 "
              "Credential=" var.s3AccessKey "/" var.scope ", "
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

  # fastly object storage bucket
  resource.aws_s3_bucket.cache.bucket = "cache";
  # RW key for Niks3
  resource.fastly_object_storage_access_keys.niks3 = {
    description = "RW key for Nix Binary Cache storage backend used by Niks3.";
    permission = "read-write-objects";
    buckets = [ (tfRef "aws_s3_bucket.cache.bucket") ];
  };
  # RO key for vcl read path (bucket scoping only applies to *-objects)
  resource.fastly_object_storage_access_keys.cache = {
    description = "RO key for Nix Binary Cache storage backend used by Cache VCL service.";
    permission = "read-only-objects";
    buckets = [ (tfRef "aws_s3_bucket.cache.bucket") ];
  };

  resource.fastly_domain.cache = {
    fqdn = domain;
    service_id = tfRef "fastly_service_vcl.cache.id";
    description = "Nix Binary Cache";
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
