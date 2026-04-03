{ lib, ... }:

{ config, pkgs, ... }:


let
  cfg = config.services.as10779;

  host = lib.blueprint.hosts.${config.networking.hostName} or null;

  gravityPrefix =
    if host != null && host ? ranet && host.ranet ? gravity
    then host.ranet.gravity.prefix
    else null;

  babelEnabled = config.networking.ranet.enable && gravityPrefix != null;
  babelKernelTable = 200;

  gravityParts = if gravityPrefix != null then lib.splitString "/" gravityPrefix else [ ];

  gravityAddr =
    if gravityParts != [ ]
    then "${lib.head gravityParts}1/${lib.last gravityParts}"
    else null;

  routeType = lib.types.submodule {
    options = {
      prefix = lib.mkOption {
        type = lib.types.str;
        description = "prefix to announce";
      };
      option = lib.mkOption {
        type = lib.types.str;
        description = "option";
      };
    };
  };

  decisionType = lib.types.submodule {
    options = {
      hostname = lib.mkOption {
        type = lib.types.str;
        description = "hostname";
      };

      interface = {
        local = lib.mkOption {
          type = lib.types.str;
          description = "local interface name that will be used to assign addresses within the announced prefixes";
        };
        primary = lib.mkOption {
          type = lib.types.str;
          description = "the primary interface (assigned by hosting provider)";
        };
      };

      ipv4.addresses = lib.mkOption {
        type = with lib.types; listOf str;
        description = "IPv4 addresses to use on local interface";
      };

      ipv6.addresses = lib.mkOption {
        type = with lib.types; listOf str;
        description = "IPv6 addresses to use on local interface";
      };
    };
  };
in
{
  options.services.as10779 = {
    enable = lib.mkEnableOption "AS10779";

    asn = lib.mkOption {
      type = lib.types.int;
      default = 10779;
      description = "ASN";
    };

    local = lib.mkOption {
      type = decisionType;
      description = "local routing decision";
    };

    router = {
      id = lib.mkOption {
        type = lib.types.str;
        default = lib.blueprint.hosts.${config.networking.hostName}.ipv4;
        description = "router ID";
      };

      exit = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "is this node capable of sending outboud traffic (i.e. have BGP session or not)";
      };

      outboundGateway = {
        ipv4 = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = ''
            IPv4 address of outbound gateway if different from main interface's default gateway
            only set this if upstream provider requires it
          '';
        };
        ipv6 = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = ''
            IPv6 address of outbound gateway if different from main interface's default gateway
            only set this if upstream provider requires it
          '';
        };
      };

      scantime = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "scan time";
      };

      secret = lib.mkOption {
        type = lib.types.path;
        description = "path to secret (imported via `include`)";
      };

      source = {
        ipv4 = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "Default IPv4 source address";
        };
        ipv6 = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "Default IPv6 source address";
        };
      };

      rpki = {
        ipv4 = {
          table = lib.mkOption {
            type = lib.types.str;
            default = "trpki4";
            description = "IPv4 RPKI table name";
          };
          filter = lib.mkOption {
            type = lib.types.str;
            default = "validated4";
            description = "IPv4 RPKI filter name";
          };
        };
        ipv6 = {
          table = lib.mkOption {
            type = lib.types.str;
            default = "trpki6";
            description = "IPv6 RPKI table name";
          };
          filter = lib.mkOption {
            type = lib.types.str;
            default = "validated6";
            description = "IPv6 RPKI filter name";
          };
        };
        retry = lib.mkOption {
          type = lib.types.int;
          default = 600;
          description = "retry time";
        };
        refresh = lib.mkOption {
          type = lib.types.int;
          default = 3600;
          description = "refresh time";
        };
        expire = lib.mkOption {
          type = lib.types.int;
          default = 7200;
          description = "expire time";
        };
        validators = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              id = lib.mkOption {
                type = lib.types.int;
                description = "id of RPKI validator (only for generating unique names)";
              };
              remote = lib.mkOption {
                type = lib.types.str;
                description = "remote address";
              };
              port = lib.mkOption {
                type = lib.types.int;
                description = "port";
              };
            };
          });
          default = [
            { id = 0; remote = "rtr.rpki.cloudflare.com"; port = 8282; }
            # { id = 1; remote = "r3k.zrh2.v.rpki.daknob.net"; port = 3323; }
          ];
          description = "RPKI validators";
        };
      };

      device.name = lib.mkOption {
        type = lib.types.str;
        default = "device0";
        description = "name of device protocol";
      };

      direct.name = lib.mkOption {
        type = lib.types.str;
        default = "direct0";
        description = "name of direct protocol";
      };

      kernel = {
        ipv4 = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "kernel4";
            description = "name of IPv4 kernel protocol";
          };
          import = lib.mkOption {
            type = lib.types.str;
            default = "import none;";
            description = "import option";
          };
          export = lib.mkOption {
            type = lib.types.str;
            default = "export none;";
            description = "export option";
          };
        };
        ipv6 = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "kernel6";
            description = "name of IPv6 kernel protocol";
          };
          import = lib.mkOption {
            type = lib.types.str;
            default = "import none;";
            description = "import option";
          };
          export = lib.mkOption {
            type = lib.types.str;
            default = "export none;";
            description = "export option";
          };
        };
      };

      static = {
        ipv4 = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "static4";
            description = "name of IPv4 static protocol";
          };
          routes = lib.mkOption {
            type = with lib.types; listOf routeType;
            description = "IPv4 prefixes to announce and their corresponding options";
          };
        };
        ipv6 = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "static6";
            description = "name of IPv6 static protocol";
          };
          routes = lib.mkOption {
            type = with lib.types; listOf routeType;
            description = "IPv6 prefixes to announce and their corresponding options";
          };
        };
      };

      sessions = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "name of BGP neighbor";
            };

            password = lib.mkOption {
              type = with lib.types; nullOr str;
              description = "key of BGP session password in the environment file";
            };

            type = {
              ipv4 = lib.mkOption {
                type = lib.types.enum [ "disabled" "direct" "multihop" ];
                description = "IPv4 peer connection type";
              };
              ipv6 = lib.mkOption {
                type = lib.types.enum [ "disabled" "direct" "multihop" ];
                description = "IPv6 peer connection type";
              };
            };

            mp = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "v4 over v6" "v6 over v4" ]);
              default = null;
              description = "BGP multi-protocol extension";
            };

            source = {
              ipv4 = lib.mkOption {
                type = with lib.types; nullOr str;
                default = cfg.router.source.ipv4;
                description = "IPv4 source address if different from router's default outbound IPv4";
              };
              ipv6 = lib.mkOption {
                type = with lib.types; nullOr str;
                default = cfg.router.source.ipv6;
                description = "IPv6 source address if different from router's default outbound IPv6";
              };
            };

            neighbor = {
              asn = lib.mkOption {
                type = lib.types.int;
                description = "ASN of BGP neighbor";
              };
              ipv4 = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = "IPv4 of BGP neighbor";
              };
              ipv6 = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = "IPv6 of BGP neighbor";
              };
            };

            addpath = lib.mkOption {
              type = lib.types.enum [ "switch" "rx" "tx" "off" ];
              default = "off";
              description = "BGP Add-Path extension";
            };

            import = {
              ipv4 = lib.mkOption {
                type = lib.types.str;
                default = "import none;";
                description = "IPv4 import option";
              };
              ipv6 = lib.mkOption {
                type = lib.types.str;
                default = "import none;";
                description = "IPv6 import option";
              };
            };

            export = {
              ipv4 = lib.mkOption {
                type = lib.types.str;
                default = "export all;";
                description = "IPv4 export option";
              };
              ipv6 = lib.mkOption {
                type = lib.types.str;
                default = "export all;";
                description = "IPv6 export option";
              };
            };

            nexthop = {
              ipv4 = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = "IPv4 next hop option";
              };
              ipv6 = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = "IPv6 next hop option";
              };
            };
          };
        });
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      networking.firewall.allowedTCPPorts = lib.optional cfg.router.exit 179;

      # router and ranet nodes all need to have bird
      services.bird.enable = cfg.router.exit || babelEnabled;
      services.bird.package = pkgs.bird3;
      services.bird.checkConfig = false;

      services.bird.config = lib.concatStrings [
        # base
        ''
          router id ${cfg.router.id};

          protocol device ${cfg.router.device.name} {
            scan time ${lib.toString cfg.router.scantime};
          }
        ''

        # babel over ranet mesh (gravity VRF)
        (lib.optionalString babelEnabled ''

          ipv4 table babel4;
          ipv6 sadr table babel6;

          protocol direct dbabel0 {
            vrf "gravity";
            interface "${cfg.local.interface.local}", "gravity";
            ipv4 { table babel4; };
            ipv6 sadr;
          }

          protocol kernel kbabel4 {
            kernel table ${lib.toString babelKernelTable};
            ipv4 {
              table babel4;
              export filter {
                krt_prefsrc = ${host.ipam.ipv4};
                accept;
              };
              import none;
            };
          }

          protocol kernel kbabel6 {
            kernel table ${lib.toString babelKernelTable};
            metric 2048;
            ipv6 sadr {
              export all;
              import none;
            };
          }

          protocol babel babel0 {
            vrf "gravity";
            randomize router id;
            ipv4 {
              table babel4;
              export where proto = "dbabel0" ${lib.optionalString cfg.router.exit ''|| proto = "exitdefault4" ''};
              import all;
            };
            ipv6 sadr {
              export where (proto = "dbabel0" ${lib.optionalString cfg.router.exit ''|| proto = "exitdefault6" ''}) && net !~ [ fe80::/10+ ];
              import all;
            };
            interface "ranet*" {
              type tunnel;
              link quality etx;
              rxcost 32;
              hello interval 20 s;
              rtt cost 1024;
              rtt max 1024 ms;
              rx buffer 1500;
            };
          }
        '')

        # exit nodes: inject default route into babel so non-exit nodes
        # route internet-bound IPAM traffic to the nearest exit via mesh
        (lib.optionalString (babelEnabled && cfg.router.exit) ''

          protocol static exitdefault4 {
            ipv4 { table babel4; };
            route 0.0.0.0/0 via "gravity";
          }

          protocol static exitdefault6 {
            ipv6 sadr;
            route ::/0 from ::/0 via "gravity";
          }
        '')

        # only on bgp exit nodes with sessions
        (lib.optionalString cfg.router.exit ''

          include "${cfg.router.secret}";

          roa4 table ${cfg.router.rpki.ipv4.table};
          roa6 table ${cfg.router.rpki.ipv6.table};

          ${lib.concatMapStringsSep
          "\n\n"
          (validator: ''
            protocol rpki rpki${lib.toString validator.id} {
              roa4 { table ${cfg.router.rpki.ipv4.table}; };
              roa6 { table ${cfg.router.rpki.ipv6.table}; };

              remote "${validator.remote}" port ${lib.toString validator.port};

              retry keep ${lib.toString cfg.router.rpki.retry};
              refresh keep ${lib.toString cfg.router.rpki.refresh};
              expire ${lib.toString cfg.router.rpki.expire};
            }'')
          cfg.router.rpki.validators}

          filter ${cfg.router.rpki.ipv4.filter} {
            if (roa_check(${cfg.router.rpki.ipv4.table}, net, bgp_path.last) = ROA_INVALID) then {
              print "Ignore RPKI invalid ", net, " for ASN ", bgp_path.last;
              reject;
            }
            accept;
          }

          filter ${cfg.router.rpki.ipv6.filter} {
            if (roa_check(${cfg.router.rpki.ipv6.table}, net, bgp_path.last) = ROA_INVALID) then {
              print "Ignore RPKI invalid ", net, " for ASN ", bgp_path.last;
              reject;
            }
            accept;
          }

          protocol direct ${cfg.router.direct.name} {
            interface "${cfg.local.interface.local}";
            ipv4;
            ipv6;
          }

          protocol kernel ${cfg.router.kernel.ipv4.name} {
            scan time ${lib.toString cfg.router.scantime};

            learn;
            persist;

            ipv4 {
              ${cfg.router.kernel.ipv4.import}
              ${cfg.router.kernel.ipv4.export}
            };
          }

          protocol kernel ${cfg.router.kernel.ipv6.name} {
            scan time ${lib.toString cfg.router.scantime};

            learn;
            persist;

            ipv6 {
              ${cfg.router.kernel.ipv6.import}
              ${cfg.router.kernel.ipv6.export}
            };
          }

          protocol static ${cfg.router.static.ipv4.name} {
            ipv4;

            ${lib.concatMapStringsSep
              "\n  "
              (r: ''route ${r.prefix} ${r.option};'')
              cfg.router.static.ipv4.routes}
          }

          protocol static ${cfg.router.static.ipv6.name} {
            ipv6;

            ${lib.concatMapStringsSep
            "\n  "
              (r: ''route ${r.prefix} ${r.option};'')
              cfg.router.static.ipv6.routes}
          }

          ${lib.concatMapStringsSep
          "\n\n"
          (session: (lib.optionalString (session.type.ipv4 != "disabled") ''
            protocol bgp ${session.name}4 {
              graceful restart on;

              ${session.type.ipv4};
              ${if (lib.isNull session.source.ipv4) then "" else ''source address ${session.source.ipv4};'' }
              local as ${lib.toString cfg.asn};
              neighbor ${session.neighbor.ipv4} as ${lib.toString session.neighbor.asn};${
                if lib.isNull session.password
                then ""
                else "\n  password ${session.password};"
              }

              ipv4 {
                add paths ${session.addpath};
                ${lib.optionalString (!lib.isNull session.nexthop.ipv4) session.nexthop.ipv4}
                ${session.import.ipv4}
                ${session.export.ipv4}
              };
              ${lib.optionalString (session.mp == "v6 over v4") ''
                ipv6 {
                    add paths ${session.addpath};
                    ${lib.optionalString (!lib.isNull session.nexthop.ipv6) session.nexthop.ipv6}
                    ${session.import.ipv6}
                    ${session.export.ipv6}
                  };''}
            }
            '') + "\n" + (lib.optionalString (session.type.ipv6 != "disabled") ''
            protocol bgp ${session.name}6 {
              graceful restart on;

              ${session.type.ipv6};
              ${if (lib.isNull session.source.ipv6) then "" else ''source address ${session.source.ipv6};'' }
              local as ${lib.toString cfg.asn};
              neighbor ${session.neighbor.ipv6} as ${lib.toString session.neighbor.asn};${
                if lib.isNull session.password
                then ""
                else "\n  password ${session.password};"
              }

              ipv6 {
                add paths ${session.addpath};
                ${lib.optionalString (!lib.isNull session.nexthop.ipv6) session.nexthop.ipv6}
                ${session.import.ipv6}
                ${session.export.ipv6}
              };
              ${lib.optionalString (session.mp == "v4 over v6") ''
                ipv4 {
                    add paths ${session.addpath};
                    ${lib.optionalString (!lib.isNull session.nexthop.ipv4) session.nexthop.ipv4}
                    ${session.import.ipv4}
                    ${session.export.ipv4}
                  };''}
            }'')) cfg.router.sessions}
        '')
      ];
    }
    {
      boot.kernelModules = [ "dummy" ];
      systemd.network.config.networkConfig.ManageForeignRoutes = false;

      systemd.network.netdevs."40-${cfg.local.interface.local}".netdevConfig = {
        Kind = "dummy";
        Name = cfg.local.interface.local;
      };

      systemd.network.networks."40-${cfg.local.interface.local}" = {
        name = cfg.local.interface.local;
        address = with cfg.local; ipv4.addresses ++ ipv6.addresses;
        networkConfig = lib.optionalAttrs babelEnabled { VRF = "gravity"; };
        routingPolicyRules = lib.remove { } (lib.flatten [
          (lib.optionalAttrs (lib.isString cfg.router.outboundGateway.ipv4) (lib.map
            (r: {
              From = r.prefix;
              Table = cfg.asn;
              Priority = 10000;
            })
            cfg.router.static.ipv4.routes))
          (lib.optionalAttrs (lib.isString cfg.router.outboundGateway.ipv6) (lib.map
            (r: {
              From = r.prefix;
              Table = cfg.asn;
              Priority = 10000;
            })
            cfg.router.static.ipv6.routes))
        ]);
      };

      networking.nftables.tables = {
        outbound4 = {
          name = "nat";
          family = "ip";
          content = ''
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              ${if cfg.router.exit then
              # if node have BGP session, SNAT Tailscale exit node traffic to announced IP
              # ''
              #   meta mark & 0x0000ff00 == 0x00000400 oifname "${cfg.local.interface.primary}" snat to ${lib.head cfg.local.ipv4.addresses}
              # ''
              ""
              else
              # if no BGP session, outbound traffic will be SNATed to the primary interface address
              # ''
              #   ip saddr { ${lib.concatMapStringsSep ", " (r: r.prefix) cfg.router.static.ipv4.routes} } oifname "${cfg.local.interface.primary}" masquerade
              # ''}
              ""}
              ip saddr != { ${lib.concatMapStringsSep ", " (r: r.prefix) cfg.router.static.ipv4.routes} } oifname "${cfg.local.interface.primary}" masquerade
            }
          '';
        };
        outbound6 = {
          name = "nat";
          family = "ip6";
          content = ''
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              ${if cfg.router.exit then
              # if node have BGP session, SNAT Tailscale exit node traffic to announced IP
              # ''
              #   meta mark & 0x0000ff00 == 0x00000400 oifname "${cfg.local.interface.primary}" snat to ${lib.head cfg.local.ipv6.addresses}
              # ''
              ""
              else
              # if no BGP session, outbound traffic will be SNATed to the primary interface address
              # ''
              #   ip6 saddr { ${lib.concatMapStringsSep ", " (r: r.prefix) cfg.router.static.ipv6.routes} } oifname "${cfg.local.interface.primary}" masquerade
              # ''}
              ""}
              ip6 saddr != { ${lib.concatMapStringsSep ", " (r: r.prefix) cfg.router.static.ipv6.routes} } oifname "${cfg.local.interface.primary}" masquerade
            }
          '';
        };
      };

      # switch to networkd dispatcher?
      networking.localCommands =
        (lib.optionalString (lib.isString cfg.router.outboundGateway.ipv4) ''
          ip -4 route replace default via ${cfg.router.outboundGateway.ipv4} table ${lib.toString cfg.asn}
        '')
        +
        (lib.optionalString (lib.isString cfg.router.outboundGateway.ipv6) ''
          ip -6 route replace default via ${cfg.router.outboundGateway.ipv6} table ${lib.toString cfg.asn}
        '')
        +
        # exit nodes: add real default route in VRF table for internet egress
        # bird's exitdefault (via "gravity") is for babel propagation only
        # on the exit node itself it's a dead end (self-referential VRF loop)
        (lib.optionalString (babelEnabled && cfg.router.exit) ''
          read _ _ gw4 _ dev4 _ < <(ip -4 route show default table main)
          [ -n "$gw4" ] && ip -4 route replace default via $gw4 dev $dev4 table ${lib.toString babelKernelTable} metric 1 || true
          read _ _ gw6 _ dev6 _ < <(ip -6 route show default table main)
          [ -n "$gw6" ] && ip -6 route replace default via $gw6 dev $dev6 table ${lib.toString babelKernelTable} metric 1 || true
        '');
    }
    (lib.mkIf babelEnabled {
      networking.iproute2.enable = true;
      networking.iproute2.rttablesExtraConfig = "${lib.toString babelKernelTable} ranet";

      # IPAM addresses on lo so default-namespace services can bind to them
      # (dummy0 is in the gravity VRF bind() from default namespace fails without this)
      systemd.network.networks."10-loopback" = {
        name = "lo";
        address = with cfg.local; ipv4.addresses ++ ipv6.addresses;
      };

      systemd.network.networks."20-gravity" = {
        name = "gravity";
        address = [ gravityAddr ];
        linkConfig.RequiredForOnline = false;
        # all nodes: direct IPAM/gravity traffic into VRF table
        routingPolicyRules =
          lib.map (r: { To = r.prefix; Table = babelKernelTable; Priority = 100; })
            cfg.router.static.ipv4.routes
          ++ lib.map (r: { To = r.prefix; Table = babelKernelTable; Priority = 100; })
            cfg.router.static.ipv6.routes
          ++ [{ To = "2a0c:b641:69c::/48"; Table = babelKernelTable; Priority = 100; }]
          # exit nodes only: IPAM-sourced traffic -> leak to main for internet egress
          # no iif constraint: must match both locally-generated VRF packets
          # (services replying) and forwarded packets (anycast return traffic)
          ++ lib.optionals cfg.router.exit (
            lib.map (r: { From = r.prefix; Table = "main"; Priority = 150; })
              cfg.router.static.ipv4.routes
            ++ lib.map (r: { From = r.prefix; Table = "main"; Priority = 150; })
              cfg.router.static.ipv6.routes
            ++ [{ From = "2a0c:b641:69c::/48"; Table = "main"; Priority = 150; }]
          );
      };
    })
    {
      services.prometheus.exporters.bird = {
        enable = with config.services; bird.enable && victoriametrics.enable;
        listenAddress = "[::1]";
        port = 9324;
      };
      services.victoriametrics.prometheusConfig.scrape_configs =
        lib.optional config.services.bird.enable
          {
            job_name = "bird";
            static_configs = [
              { targets = [ "${config.services.prometheus.exporters.bird.listenAddress}:${lib.toString config.services.prometheus.exporters.bird.port}" ]; }
            ];
          }
        ++ [{
          job_name = "bgptools";
          scheme = "https";
          static_configs = [{ targets = [ "prometheus.bgp.tools:443" ]; }];
          metrics_path = "/prom/1dafeced-2b12-40c0-a173-e9296ddb6df4";
        }];
    }
  ]);
}
