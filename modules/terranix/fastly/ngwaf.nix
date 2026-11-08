{ lib, ... }:

let
  inherit (lib.terranix) tfRef;
  inherit (lib.blueprint) services;

  workspace = tfRef "fastly_ngwaf_workspace.ngwaf.id";

  is = field: value: { inherit field value; operator = "equals"; };

  # like = field: value: { inherit field value; operator = "like"; };

  any = condition: { group_operator = "any"; inherit condition; };

  # allow action will win over every block action but keeps inspection and tagging
  allow = { description, signal, condition ? [ ], group_condition ? [ ], multival_condition ? [ ] }: {
    workspace_id = workspace;
    type = "request";
    inherit description condition group_condition multival_condition;
    enabled = true;
    request_logging = "sampled";
    group_operator = "all";
    action = [
      { type = "allow"; }
      { type = "add_signal"; signal = tfRef "fastly_ngwaf_workspace_signal.${signal}.reference_id"; }
    ];
  };

  # a request header or cookie with this name is present
  has = field: name: { inherit field; operator = "exists"; group_operator = "all"; condition = [ (is "name" name) ]; };
  header = has "request_header";
  cookie = has "request_cookie";
  # contentType = value: {
  #   field = "request_header";
  #   operator = "exists";
  #   group_operator = "all";
  #   condition = [ (is "name" "Content-Type") { field = "value_string"; operator = "contains"; inherit value; } ];
  # };

  # see tailscale snippet in modules/nixos/caddy/default.nix
  tailnet = [ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ];
in
{
  resource.fastly_ngwaf_workspace.ngwaf = {
    name = "NGWAF";
    description = "Next-Gen WAF";
    mode = "block";

    auto_enable_new_virtual_patches = true;

    # this block is required
    attack_signal_thresholds = [{
      immediate = true;
      one_minute = 50;
      ten_minutes = 350;
      one_hour = 1800;
    }];
  };

  # the api cannot rename a signal, so a new name replaces it and the rules must move to the new one first
  resource.fastly_ngwaf_workspace_signal = lib.mapAttrs
    (_: signal: signal // {
      workspace_id = workspace;
      lifecycle.create_before_destroy = true;
    })
    {
      niks3 = { name = "Niks3 Push"; description = "Authenticated calls to the niks3 API from a binary cache push."; };
      plausible = { name = "Plausible Beacon"; description = "Analytics events posted by the plausible tracker script."; };
      reports = { name = "CSP Report"; description = "CSP and NEL reports posted by browsers to the collector."; };
      tailnet = { name = "Tailnet Client"; description = "Requests from tailnet addresses to the sites that only answer the tailnet."; };
      kanidm = { name = "Kanidm Credential"; description = "Passwords and codes posted to the Kanidm login forms and auth API."; };
      grafana = { name = "Grafana Session"; description = "Requests from a signed in Grafana browser session."; };
      neogrok = { name = "Neogrok Search"; description = "Code searches from a session that passed the Caddy OIDC gate."; };
    };

  resource.fastly_ngwaf_workspace_rule = {
    # niks3 client call carries bearer token
    # uploads go to s3 through presigned urls
    niks3 = allow {
      description = "Allow authenticated niks3 API calls on ${services.niks3.domain}.";
      signal = "niks3";
      condition = [ (is "domain" services.niks3.domain) ];
      multival_condition = [ (header "Authorization") ];
    };

    # browsers only post beacon events here
    # dashboard login is the other post but plausible checks it itself
    plausible = allow {
      description = "Allow posts to the plausible beacon on ${services.plausible.domain}.";
      signal = "plausible";
      condition = [ (is "domain" services.plausible.domain) (is "method" "POST") ];
    };

    # modules/nixos/go-csp-collector.nix proxies posts only and redirects everything else
    reports = allow {
      description = "Allow browser CSP and NEL reports posted to ${services.go-csp-collector.domain}.";
      signal = "reports";
      condition = [ (is "domain" services.go-csp-collector.domain) (is "method" "POST") ];
    };

    # tailnet srcaddr only reach sites resolve to tailnet
    # caddy will 404 to everything else
    tailnet = allow {
      description = "Allow tailnet clients on the sites that only answer the tailnet.";
      signal = "tailnet";
      group_condition = [ (any (map (is "ip") tailnet)) ];
    };

    # passwords and 2fc code will be in POST
    # kanidm has no injectable backend
    kanidm = allow {
      description = "Allow posts to the Kanidm login forms and auth API on ${services.kanidm.domain}.";
      signal = "kanidm";
      condition = [ (is "domain" services.kanidm.domain) (is "method" "POST") ];
    };

    # explore puts LogQL in query string
    # grafana_session is the documented login cookie
    # shared dashboards and embeds are fetched anonymously
    # e.g. (grafana 13.1.4)
    #   /public-dashboards/<token>
    #   /api/public/dashboards/<token>
    # other anonymous traffic stays enforced
    grafana = allow {
      description = "Allow requests from a signed in Grafana session or to a shared dashboard on ${services.grafana.domain}.";
      signal = "grafana";
      condition = [ (is "domain" services.grafana.domain) ];
      group_condition = [{
        group_operator = "any";
        condition = map (value: { field = "path"; operator = "like"; inherit value; }) [ "/public-dashboards/*" "/api/public/dashboards/*" ];
        multival_condition = [ (cookie "grafana_session") ];
      }];
    };

    # code search look like attacks
    # `session` is the cookie `(auth)` snippet configures
    # caddy validates it before proxying
    neogrok = allow {
      description = "Allow code searches from a session that passed the Caddy OIDC gate on ${services.neogrok.domain}.";
      signal = "neogrok";
      condition = [ (is "domain" services.neogrok.domain) ];
      multival_condition = [ (cookie "session") ];
    };
  };
}
