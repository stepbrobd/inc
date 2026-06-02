{ ... }:

{
  resource.fastly_service_vcl.ysun = {
    name = "ysun.co";
    http3 = true;
    default_ttl = 60;

    product_enablement = [{ brotli_compression = true; }];

    domain = [
      { name = "ysun.global.ssl.fastly.net"; }
      { name = "stepbrobd.global.ssl.fastly.net"; }
    ];

    backend = [{
      name = "ysun.co";
      address = "ysun.co";
      port = 443;
      use_ssl = true;
      override_host = "ysun.co";
      ssl_cert_hostname = "ysun.co";
      ssl_sni_hostname = "ysun.co";
      prefer_ipv6 = true;
      healthcheck = "ysun.co";
    }];

    healthcheck = [{
      name = "ysun.co";
      host = "ysun.co";
      path = "/";
      check_interval = 2000;
      window = 10;
      threshold = 7;
      initial = 9;
    }];

    gzip = [{
      name = "compression";
      content_types = [
        "application/atom+xml"
        "application/javascript"
        "application/json"
        "application/rss+xml"
        "application/vnd.ms-fontobject"
        "application/wasm"
        "application/x-javascript"
        "application/xml"
        "font/eot"
        "font/otf"
        "font/ttf"
        "image/svg+xml"
        "image/vnd.microsoft.icon"
        "text/css"
        "text/html"
        "text/javascript"
        "text/plain"
        "text/xml"
      ];
      extensions = [
        "css"
        "eot"
        "html"
        "ico"
        "js"
        "json"
        "mjs"
        "otf"
        "svg"
        "ttf"
        "txt"
        "wasm"
        "xml"
      ];
    }];

    request_setting = [{
      name = "force-ssl";
      force_ssl = true;
    }];

    header = [{
      name = "hsts";
      action = "set";
      type = "response";
      destination = "http.Strict-Transport-Security";
      source = ''"max-age=31536000"'';
      ignore_if_set = false;
    }];

    snippet = [{
      name = "cache";
      type = "fetch";
      priority = 110;
      content = ''
        if (beresp.ttl > 60s) {
          set beresp.ttl = 60s;
        }
        set beresp.stale_while_revalidate = 60s;
        set beresp.stale_if_error = 86400s;
      '';
    }];
  };
}
