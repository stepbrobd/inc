{ lib, ... }:

{ config, pkgs, ... }:


let
  cfg = config.services.as10779;

  host = lib.blueprint.hosts.${config.networking.hostName} or null;

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

      advertiseDefault = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "whether this node injects its default route into Babel for other mesh nodes";
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
        enable = lib.mkEnableOption "RPKI route origin validation RTR session(s)";
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
                default = "export none;";
                description = "IPv4 export option";
              };
              ipv6 = lib.mkOption {
                type = lib.types.str;
                default = "export none;";
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
      # bgp is only ever spoken to configured peers
      # while bird rejects unknown peers on its own
      # keeping 179 open would allow scanner connects in its log
      networking.firewall.extraInputRules = lib.optionalString cfg.router.exit (
        let
          peers = family: lib.filter (a: a != null) (lib.map
            (session: if session.type.${family} == "disabled" then null else session.neighbor.${family})
            cfg.router.sessions);

          rule = keyword: family: lib.optionalString (peers family != [ ]) ''
            ${keyword} saddr { ${lib.concatStringsSep ", " (peers family)} } tcp dport 179 accept
          '';
        in
        rule "ip" "ipv4" + rule "ip6" "ipv6"
      );

      # bird speaks bgp alone, ranet3 speaks babel
      services.bird.enable = cfg.router.exit;
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

        # only on bgp exit nodes with sessions
        (lib.optionalString cfg.router.exit ''

          include "${cfg.router.secret}";

          ${lib.optionalString cfg.router.rpki.enable ''

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
            }''}

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
              graceful restart aware;
              hold time 30;
              keepalive time 10;

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
              graceful restart aware;
              hold time 30;
              keepalive time 10;

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
        # ranet3 puts the ipam pair on its tun through cap.table.addresses
        address =
          let all = with cfg.local; ipv4.addresses ++ ipv6.addresses;
          in if config.networking.ranet3.enable then lib.subtractLists [ "${host.ipam.ipv4}/32" "${host.ipam.ipv6}/128" ] all else all;
        routingPolicyRules = lib.remove { } (lib.flatten [
          # bird's bgp sessions leave by main whatever the mesh's table holds for a neighbor
          # ranet3 reads its table for every lookup that main has no route longer than /0 for
          (lib.optionals (cfg.router.exit && config.networking.ranet3.enable) (lib.map
            (a: { From = a; Table = "main"; Priority = 5300; })
            (lib.unique (lib.filter (a: a != null) (lib.concatMap
              (s: [ s.source.ipv4 s.source.ipv6 ])
              ([{ inherit (cfg.router) source; }] ++ cfg.router.sessions))))))
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
              # a packet for the node's own uplink address leaves by the uplink only while that address is tentative
              # masquerading it binds the flow to lo's first global address for as long as the peer keeps sending
              ${lib.optionalString (host != null && host ? ipv6) "ip6 daddr ${host.ipv6} return"}
              ip6 saddr != { ${lib.concatMapStringsSep ", " (r: r.prefix) cfg.router.static.ipv6.routes} } oifname "${cfg.local.interface.primary}" masquerade
            }
          '';
        };

        # fix PMTU blackhole on the anycast overlay
        # client packets ingress over the 1400 MTU mesh
        # but an exit node SYN ACK egresses its native primary iface at 1500
        # so the kernel advertises a 1500 derived mss (1460 on the wire)
        # big segments (e.g. a post quantum TLS ClientHello) then overshoot the 1400 ingress and get undropped
        mssClamp =
          let
            mss = 1328; # 1400 - 20 - 20 - 12
            addrs = lib.concatMapStringsSep ", " (a: lib.head (lib.splitString "/" a));
            v4 = cfg.local.ipv4.addresses;
            v6 = cfg.local.ipv6.addresses;
          in
          {
            name = "mssclamp";
            family = "inet";
            content = ''
              chain output {
                type filter hook output priority mangle; policy accept;
                ${lib.optionalString (v4 != [ ]) ''tcp flags & syn == syn ip saddr { ${addrs v4} } tcp option maxseg size gt ${toString mss} tcp option maxseg size set ${toString mss}''}
                ${lib.optionalString (v6 != [ ]) ''tcp flags & syn == syn ip6 saddr { ${addrs v6} } tcp option maxseg size gt ${toString mss} tcp option maxseg size set ${toString mss}''}
              }
            '';
          };
      };

      services.networkd-dispatcher.rules =
        let
          asnTable = lib.toString cfg.asn;
          hasStaticGw4 = lib.isString cfg.router.outboundGateway.ipv4;
          hasStaticGw6 = lib.isString cfg.router.outboundGateway.ipv6;
          needsRule = hasStaticGw4 || hasStaticGw6;

          script = ''
            #!${pkgs.runtimeShell}

            export PATH=${pkgs.lib.makeBinPath (with pkgs; [ coreutils iproute2 ])}

            ${lib.optionalString hasStaticGw4 ''
              ip -4 route replace default via ${cfg.router.outboundGateway.ipv4} table ${asnTable}
            ''}
            ${lib.optionalString hasStaticGw6 ''
              ip -6 route replace default via ${cfg.router.outboundGateway.ipv6} table ${asnTable}
            ''}
          '';
        in
        lib.mkIf needsRule {
          "40-gravity-routes" = {
            onState = [ "routable" ];
            inherit script;
          };
        };
    }
    (lib.mkIf cfg.router.exit {
      systemd.network.networks."10-loopback" = {
        name = "lo";
        # TODO: FIXME: make 192.104.136.0/24 temporarily pingable on BGP exit nodes
        routes = [{ Destination = "192.104.136.0/24"; Type = "local"; }];
        # can be removed but also drop the below firewall rules for bgo.tools art drawn in hilbert curve
      };
      #   ................
      #   ....#...#..#....
      #   ....##..####....
      #   ....##...##.....
      #   ..#########..#..
      #   .....#....##.#..
      #   ....##....####..
      #   #####......#####
      #   #####......#####
      #   ..####....##....
      #   ..#.##....#.....
      #   ..#..#########..
      #   .....##...##....
      #   ....####..##....
      #   ....#..#...#....
      #   ................
      networking.nftables.tables.snowflake = (
        let
          # one list per row left to right
          lit = lib.concatLists [
            [ ]
            [ 17 233 238 ]
            [ 30 29 230 231 226 225 ]
            [ 31 28 228 227 ]
            [ 54 53 32 35 36 37 218 219 220 201 ]
            [ 34 221 222 200 ]
            [ 46 45 210 209 204 205 ]
            [ 63 62 49 48 47 208 207 206 193 192 ]
            [ 64 67 68 69 122 133 186 187 188 191 ]
            [ 71 70 121 120 135 134 ]
            [ 72 118 119 136 ]
            [ 75 116 115 112 143 140 139 138 181 180 ]
            [ 97 110 158 159 ]
            [ 99 98 109 108 157 156 ]
            [ 100 107 155 ]
            [ ]
          ];
        in
        {
          family = "ip";
          content = ''
            set lit {
              type ipv4_addr
              elements = { ${lib.concatMapStringsSep ", " (o: "192.104.136.${toString o}") lit} }
            }

            chain input {
              type filter hook input priority filter; policy accept;
              icmp type echo-request ip daddr 192.104.136.0/24 ip daddr != @lit drop
            }
          '';
        }
      );
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
