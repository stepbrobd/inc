---
title: Kanidm LDAP guide
description: How I setup Kanidm's read-only LDAP to work with Hydra build server
created: 2025-02-02
updated: 2026-02-12
---

> If you are reading this to setup SSO for Hydra, it might be better to follow
> the [Hydra OIDC guide](/hydra) instead. Since... you know... this is LDAP...
> But if you just want to read about Kanidm's read-only LDAP setup, go ahead!

Couple months back, I met [Nick](https://nichi.co) (one of the most legendary
`nixpkgs` contributors) IRL, and he introduced me to this fairly new and
interesting CLI based
[IDM](https://en.wikipedia.org/wiki/Identity_and_access_management) tool called
[Kanidm](https://github.com/kanidm/kanidm). Fast-forward to mid-January, I got
bored with my research and wanted to mess around with my
[Hydra](https://github.com/NixOS/hydra) build server, and I thought it would be
cool to use Kanidm as the LDAP backend for Hydra (I was using local Hydra
accounts).

## Installation (with NixOS of course)

I'll skip the NixOS introduction here, go look for the manual and wiki if you're
not already familiar with it. Here's the base config:

```nix
{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 636 ];

  services.kanidm = {
    package = pkgs.kanidm.override { enableSecretProvisioning = true; };

    enableClient = true;
    clientSettings.uri = config.services.kanidm.serverSettings.origin;

    enableServer = true;
    serverSettings = {
      domain = "ysun.co";
      origin = "https://sso.ysun.co";
      trust_x_forward_for = true;
      ldapbindaddress = "0.0.0.0:636";
      bindaddress = "0.0.0.0:8443";
    };
  };

  services.caddy.virtualHosts."sso.ysun.co".extraConfig = ''
      reverse_proxy ${config.services.kanidm.provision.instanceUrl} {
        header_up Host {host}
        header_up X-Real-IP {http.request.header.CF-Connecting-IP}
      }
  '';
}
```

I want to use Caddy to proxy the Kanidm web interface, and since Caddy handles
HTTP traffic, LDAP won't be proxied by Caddy, so opening port 636 is required
for LDAP(s) requests. Also since we'll be proxing the web interface (and I
usually proxy all my web services behind Cloudflare), we need to rename the
`CF-Connecting-IP` header to `X-Real-IP` so Kanidm can get the real IP of the
client.

The
[Kanidm options](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=kanidm)
gave a pretty obvious hint that you'll need a trusted certificate to expose the
web interface and LDAP server, but I want to use
[Caddy](https://github.com/caddyserver/caddy) to proxy all my services. So I
opted for an ACME cert and importing the cert into Caddy instead of having Caddy
generate a separate one. As both Caddy and Kanidm require access to ACME certs,
we need to create a group to share access for the two users:

```nix
{
  users.groups.sso.members = [ "caddy" "kanidm" ];
  security.acme.certs."sso.ysun.co" = {
    domain = "sso.ysun.co";
    extraDomainNames = [ "ldap.ysun.co" ];
    group = "sso";
    reloadServices = [ "caddy.service" "kanidm.service" ];
  };
}
```

With the above config, ACME will generate a cert for `sso.ysun.co` and
`ldap.ysun.co` (important!), and after a renewal, `caddy` and `kanidm` services
will be reloaded to pick up the new cert. The reason why I'm creating a cert
with two FQDNs is that Cloudflare only proxy some specific ports, LDAP(s) port
636 is not one of them, so I'll be proxying the web frontend through Cloudflare
on `sso.ysun.co` and the LDAP server directly (without Cloudflare) on
`ldap.ysun.co`.

Now we've got to get the path of the ACME cert for Caddy and Kanidm to use:

```nix
{ config, pkgs, ... }:

let
  inherit (config.security.acme.certs."sso.ysun.co") directory;
in
{
  services.kanidm = {
    ...
    serverSettings = {
      ...
      tls_key = "${directory}/key.pem";
      tls_chain = "${directory}/fullchain.pem";
    };
  };

  services.caddy.virtualHosts."sso.ysun.co".extraConfig = ''
      tls "${directory}/fullchain.pem" "${directory}/key.pem"
      ...
  '';
}
```

The last thing we need is to set two admin passwords for Kanidm, one for `admin`
(system admin) and one for `idm_admin` (account and group admin). I'm using SOPS
to manage secrets, and I'm lazy, so I'm just going to use the same password for
both:

```nix
{ config, pkgs, ... }:

{
  sops.secrets.kanidm = {
    owner = "kanidm";
    group = "kanidm";
  };

  services.kanidm = {
    ...
    provision = {
      adminPasswordFile = config.sops.secrets.kanidm.path;
      idmAdminPasswordFile = config.sops.secrets.kanidm.path;
      ...
    };
  };
}
```

## Provisioning users and groups

The NixOS module we are using allows users to provision users and groups
declaratively, but only for regular users and groups (we'll be using service
accounts, but the module can't manage those, more on this later).

```nix
{
  services.kanidm.provision = {
    enable = true;
    autoRemove = true;

    groups = {
      "hydra.admins" = { };
      "hydra.users" = { };
    };

    persons = {
      ysun = {
        displayName = "Yifei";
        mailAddresses = [ "ysun@duck.com" ];
        groups = [ "hydra.admins" "hydra.users" ];
      };
    };
  };
}
```

After this step, create a temporary password in the CLI, and send it to the
user. Users can change their password through the web interface. After this, you
should be able to access the Kanidm web interface at whatever domain you set up
and the LDAP query interface will also be available with anonymous read-only
access:
`nix shell nixpkgs#openldap -c ldapsearch -H ldaps://<fqdn> -x -b "spn=<username>@<server settings domain>,dc=<second level>,dc=<top level>"`

## POSIX accounts

Don't rush! The LDAP server is still non-functional. Since
[Kanidms LDAP](https://kanidm.github.io/kanidm/stable/integrations/ldap.html)
does not have 2FA, and it's read-only, you'll need to hop on the server and
migrate the account you created to a
[POSIX account](https://kanidm.github.io/kanidm/stable/accounts/posix_accounts_and_groups.html)
(can't do it through the web interface nor declaratively).

```console
$ kanidm login -D idm_admin
$ kanidm person posix set <username> --shell <full path to login shell>
```

You should be prompted to set a password for the user (can be different from the
web password), and you can also set the user's home directory.

## Service accounts

Kanidm's LDAP anonymous queries have limited access to user/group information,
so you'll need to create a
[service account](https://kanidm.github.io/kanidm/stable/accounts/service_accounts.html)
and token under `idm_admin` to allow Hydra or any other service to query LDAP.

```console
$ kanidm service-account create search "Search" idm_admin
$ kanidm service-account api-token generate search "Search"
```

With the token, try binding the LDAP server with the service account:

```console
$ nix run nixpkgs#openldap -c ldapsearch -H ldaps://<fqdn> -x -D "dn=token" -W
# type in the token
search@<fqdn>
```

## Give search user email read permission

Almost there, but not quite. The service account can't read email addresses by
default, and Hydra needs to read the email address. So we need to
[give the service account read permission](https://kanidm.github.io/kanidm/stable/access_control/intro.html?highlight=mail#:~:text=read%20mail%20attributes%20needed%20to%20be%20a%20mail%20server)
to user email addresses.

```console
$ kanidm group add-members idm_mail_servers search
```

## Appendix: full config

Example DNS settings:

```txt
abc.example.com   A      127.0.0.1 # use your real IPv4
abc.example.com   AAAA   ::1       # use your real IPv6
sso.example.com   CNAME  abc.example.com # proxied by Cloudflare
ldap.example.com  CNAME  abc.example.com # not proxied by Cloudflare
```

Example LDAP consumer config
([Hydra](https://github.com/NixOS/hydra/blob/master/doc/manual/src/configuration.md)):

```nix
{ config, ... }:

{
  services.caddy.virtualHosts."hydra.ysun.co".extraConfig = ''
      reverse_proxy ${toString config.services.hydra.listenHost}:${toString config.services.hydra.port}
  '';

  sops.secrets.hydra = {
    owner = "hydra";
    group = "hydra";
    mode = "440";
  };

  services.hydra = {
    enable = true;
    extraConfig = ''
      <ldap>
        <config>
          <credential>
            class = Password
            password_field = password
            password_type = self_check
          </credential>
          <store>
            class = LDAP
            ldap_server = "ldaps://ldap.ysun.co"
            <ldap_server_options>
              timeout = 30
            </ldap_server_options>
            binddn = "dn=token"
            include ${config.sops.secrets.hydra.path}
            start_tls = 0
            <start_tls_options>
              verify = none
            </start_tls_options>
            user_basedn = "dc=ysun,dc=co"
            user_filter = "(&(class=person)(name=%s))"
            user_scope = one
            user_field = name
            <user_search_options>
              attrs = "+"
              attrs = "cn"
              attrs = "mail"
              deref = always
            </user_search_options>
            use_roles = 1
            role_basedn = "dc=ysun,dc=co"
            role_filter = "(&(class=group)(member=%s))"
            role_scope = one
            role_field = name
            role_value = spn
            <role_search_options>
              attrs = "+"
              attrs = "cn"
              deref = always
            </role_search_options>
          </store>
        </config>
        <role_mapping>
          hydra.admins = admin
          hydra.admins = bump-to-front
          hydra.users = cancel-build
          hydra.users = eval-jobset
          hydra.users = create-projects
          hydra.users = restart-jobs
        </role_mapping>
      </ldap>
    '';
  };
}
```

Kanidm's config:

```nix
{ config, pkgs, ... }:

let
  inherit (config.security.acme.certs."sso.ysun.co") directory;
in
{
  networking.firewall.allowedTCPPorts = [ 636 ];

  environment.systemPackages = with pkgs; [ kanidm ];

  services.caddy = {
    enable = true;
    virtualHosts."sso.ysun.co".extraConfig = ''
      import common
      tls "${directory}/fullchain.pem" "${directory}/key.pem"
      reverse_proxy ${config.services.kanidm.provision.instanceUrl} {
        header_up Host {host}
        header_up X-Real-IP {http.request.header.CF-Connecting-IP}
        transport http {
            tls_server_name sso.ysun.co
        }
      }
    '';
  };

  sops.secrets.kanidm = {
    owner = "kanidm";
    group = "kanidm";
  };

  services.kanidm = {
    package = pkgs.kanidm.override { enableSecretProvisioning = true; };

    enableClient = true;
    clientSettings.uri = config.services.kanidm.serverSettings.origin;

    enableServer = true;
    serverSettings = {
      domain = "ysun.co";
      origin = "https://sso.ysun.co";
      trust_x_forward_for = true;

      ldapbindaddress = "0.0.0.0:636";
      bindaddress = "0.0.0.0:8443";

      tls_key = "${directory}/key.pem";
      tls_chain = "${directory}/fullchain.pem";
    };

    provision = {
      enable = true;
      autoRemove = true;

      adminPasswordFile = config.sops.secrets.kanidm.path;
      idmAdminPasswordFile = config.sops.secrets.kanidm.path;

      groups = {
        "hydra.admins" = { };
        "hydra.users" = { };
      };

      persons = {
        ysun = {
          displayName = "Yifei";
          legalName = "Yifei Sun";
          mailAddresses = [ "ysun@duck.com" ];
          groups = [ "hydra.admins" "hydra.users" ];
        };
      };
    };
  };

  users.groups.sso.members = [ "caddy" "kanidm" ];
  security.acme.certs."sso.ysun.co" = {
    domain = "sso.ysun.co";
    extraDomainNames = [ "ldap.ysun.co" ];
    group = "sso";
    reloadServices = [ "caddy.service" "kanidm.service" ];
  };
}
```
