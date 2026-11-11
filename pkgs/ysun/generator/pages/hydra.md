---
title: Hydra OIDC guide
description: Use Kanidm as the OIDC backend for Hydra
created: 2025-09-09
updated: 2026-05-30
---

> I've dropped Hydra as of May 30, 2026 and fully switched to my new toy
> [atelier](https://github.com/stepbrobd/atelier). It (at least partially)
> replicates the Garnix experience (rip btw) and pushes built closures to my
> cache server.

[Previously](/kanidm), we covered how to set up Kanidm's read-only LDAP
interface and get SSO working on Hydra. That's great and all, but LADP is a bit
too old school. In [this patch](https://github.com/nixos/hydra/pull/1298),
[@lheckemann](https://github.com/lheckemann) and
[@ners](https://github.com/ners) added support for OpenID Connect to Hydra.

## Hydra setup

Since the PR is not merged yet, bring in the patch manually (ignore this step if
it is merged by the time you read this):

```nix
# in flake.nix
{
  inputs.hydra.url = "github:ners/hydra/oidc";
  inputs.hydra.inputs.nixpkgs.follows = "nixpkgs";
  ...
}

# in hydra config
{ inputs, pkgs, ... }:

{
  services.hydra = {
    package = inputs.hydra.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
```

## Kanidm config

Assuming your login user name is `somebody`, the Hydra user and admin groups are
`hydra.users` and `hydra.admins`, and your Hydra instance is at
`https://hydra.example.com`, the Kanidm config should looks like this:

```nix
{
  # i only added configs related to hydra here
  # and its assumed that the kanidm domain is set to sso.example.com (where cookie is valid)
  # and kanidm is running at https://sso.example.com
  services.kanidm.provision = {
    groups = {
      "hydra.admins" = { };
      "hydra.users" = { };
    };

    persons = {
      somebody = {
        displayName = "Somebody";
        legalName = "Real Name";
        mailAddresses = [ "somebody@example.com" ];
        groups = [
          "hydra.admins"
          "hydra.users"
        ];
      };
    };

    systems.oauth2 = {
      hydra = {
        displayName = "Hydra";
        allowInsecureClientDisablePkce = true;
        originUrl = "https://hydra.example.com/oidc-login";
        originLanding = "https://hydra.example.com/";
        basicSecretFile = ""; # path to your secret file
        preferShortUsername = true;
        scopeMaps."hydra.users" = [
          "openid"
          "email"
          "profile"
          "groups"
        ];
      };
    };
  };
}
```

At the time of writing, Hydra OIDC implementation does not support PKCE, so
`allowInsecureClientDisablePkce` must be set to prevent login failure.

## Hydra config

```nix
{
  # i'm using sops for secret management
  # but you can also use other solutions
  sops.secrets.hydra = {
    owner = "hydra";
    group = "hydra";
    mode = "440";
  };

  services.hydra.extraConfig = ''
    enable_hydra_login = 0                                                     # disable default hydra login page
    enable_oidc_login = 1                                                      # enable OIDC
    oidc_client_id = "hydra"                                                   # this should match the client id in kanidm config
    oidc_scope = "openid email profile groups"                                 # scopes to request
    oidc_auth_uri = "https://sso.example.com/ui/oauth2"                        # kanidm oauth2 auth endpoint
    oidc_token_uri = "https://sso.example.com/oauth2/token"                    # kanidm oauth2 token endpoint
    oidc_userinfo_uri = "https://sso.example.com/oauth2/openid/hydra/userinfo" # kanidm userinfo endpoint, client id must match
    include ${config.sops.secrets.hydra.path}                                  # should contain `oidc_client_secret = <secret>`

    # change the role mapping according to your needs
    # but the the format is:
    # <group in kanidm> = <role in hydra>
    # where group in kanidm is in the form of
    # <group>@<kanidm cookie domain>
    <oidc_role_mapping>
      hydra.admins@sso.example.com = admin
      hydra.admins@sso.example.com = bump-to-front
      hydra.users@sso.example.com = cancel-build
      hydra.users@sso.example.com = eval-jobset
      hydra.users@sso.example.com = create-projects
      hydra.users@sso.example.com = restart-jobs
    </oidc_role_mapping>
  '';
}
```
