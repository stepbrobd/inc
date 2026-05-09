{ config, ... }:

{
  sops.secrets.acme = { };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "ysun@hey.com";
      dnsProvider = "cloudflare";
      profile = "shortlived";
      extraLegoFlags = [
        "--dns.resolvers=[2606:4700:4700::1111]:53"
        "--dns.resolvers=1.1.1.1:53"
      ];
      environmentFile = config.sops.secrets.acme.path;
    };
  };
}
