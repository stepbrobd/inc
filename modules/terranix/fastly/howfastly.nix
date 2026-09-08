{ lib, ... }:

let
  inherit (lib.terranix) tfRef;
  plausible = lib.blueprint.services.plausible.domain;
in
{
  resource.fastly_secretstore.howfastly = {
    name = "HowFastly";
  };

  resource.fastly_kvstore.howfastly = {
    name = "HowFastly";
    location = "EU";
  };

  resource.fastly_service_compute.howfastly = {
    name = "HowFastly";

    activate = false;

    product_enablement = [{
      name = "howfastly";
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

    domain = [
      { name = "speed.edgecompute.app"; }
      { name = "howfastly.edgecompute.app"; }
    ];

    backend = [
      {
        name = "fastly";
        address = "api.fastly.com";
        port = 443;
        use_ssl = true;
        ssl_cert_hostname = "api.fastly.com";
        ssl_sni_hostname = "api.fastly.com";
        override_host = "api.fastly.com";
        prefer_ipv6 = true;
        healthcheck = "fastly";
        connect_timeout = 1000;
        first_byte_timeout = 3000;
        between_bytes_timeout = 3000;
      }
      {
        name = "plausible";
        address = plausible;
        port = 443;
        use_ssl = true;
        ssl_cert_hostname = plausible;
        ssl_sni_hostname = plausible;
        override_host = plausible;
        prefer_ipv6 = true;
        healthcheck = "plausible";
        connect_timeout = 1000;
        first_byte_timeout = 2000;
        between_bytes_timeout = 2000;
      }
    ];

    healthcheck = [
      {
        name = "fastly";
        host = "api.fastly.com";
        path = "/public-ip-list";
        method = "HEAD";
        expected_response = 200;
        check_interval = 30000;
        timeout = 5000;
        window = 5;
        threshold = 3;
        initial = 3;
      }
      {
        name = "plausible";
        host = plausible;
        path = "/api/health";
        method = "HEAD";
        expected_response = 200;
        check_interval = 60000;
        timeout = 5000;
        window = 5;
        threshold = 3;
        initial = 3;
      }
    ];

    resource_link = [
      {
        name = "secretstore";
        resource_id = tfRef "fastly_secretstore.howfastly.id";
      }
      {
        name = "kvstore";
        resource_id = tfRef "fastly_kvstore.howfastly.id";
      }
    ];

    lifecycle.ignore_changes = [ "package" ];
  };
}
