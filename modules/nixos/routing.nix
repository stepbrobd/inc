{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  settings = config.services.bird.settings;

  inherit (lib.router) bird;

  asn = 10779;

  hasTag = lib.hasTag config.networking.hostName;
  exit = hasTag "router";

  host = lib.blueprint.hosts.${config.networking.hostName} or null;

  inherit (lib.blueprint.prefixes) anycast experimental unicast;

  suffix = family: if family == "ipv4" then "4" else "6";
  inFamily = family: address: lib.hasInfix ":" address == (family == "ipv6");

  ipam = { ipv4 = "${host.ipam.ipv4}/32"; ipv6 = "${host.ipam.ipv6}/128"; };

  # the ipam pair, and on routers the personal site anycast
  addresses = family: [ ipam.${family} ] ++ lib.optionals exit anycast.${family};

  # the space this node treats as its own
  # on routers whatever the static protocols announce, elsewhere the block its ipam pair comes from
  prefixes = family:
    if exit
    then lib.map (route: route.prefix) settings.protocol.static."static${suffix family}".route
    else unicast.${family};

  # whether hosts/*/routing.nix give this router traffic engineering
  origin = settings ? function.origin;

  route = family: prefix: { inherit prefix; unreachable = true; } // (
    # the experimental space is announced as originated by AS18932
    if lib.elem prefix experimental.${family} then { body = "bgp_path.prepend(18932);"; }
    # a router's traffic engineering
    else lib.optionalAttrs origin { body = "origin();"; }
  );

  # hosts/*/routing.nix derive their sessions from it
  upstream = family: {
    local.as = asn;
    direct = true;
    source-address = host.${family};
    graceful-restart-aware = true;
    hold-time = 30;
    keepalive-time = 10;
    ${family} = {
      import = "none";
      export.where = ''proto = "static${suffix family}"'';
    };
  };

  # every session with its template chain applied
  bgp = lib.filter (p: !(p.disabled or false)) (lib.attrValues ((bird.resolve settings).protocol.bgp or { }));
in
{
  imports = [ inputs.router.nixosModules.bird ];

  config = lib.mkIf (hasTag "router" || hasTag "routee") (lib.mkMerge [
    (lib.mkIf exit {
      # bgp is only ever spoken to configured peers
      # while bird rejects unknown peers on its own
      # keeping 179 open would allow scanner connects in its log
      networking.firewall.extraInputRules =
        let
          peers = family: lib.filter (inFamily family) (lib.map (p: p.neighbor.address) bgp);

          rule = keyword: family: lib.optionalString (peers family != [ ]) ''
            ${keyword} saddr { ${lib.concatStringsSep ", " (peers family)} } tcp dport 179 accept
          '';
        in
        rule "ip" "ipv4" + rule "ip6" "ipv6";

      # bird speaks bgp alone, ranet3 speaks babel
      services.bird.enable = true;
      # router's settings only render for the bird source they were generated from
      services.bird.package = inputs.router.packages.${pkgs.stdenv.hostPlatform.system}.bird;
      # bird resolves the relative include next to bird.conf, the secret at runtime
      # and in the check a fixture defining each session's password symbol
      environment.etc."bird/bgp.conf".source = config.sops.secrets.bgp.path;
      services.bird.preCheckConfig =
        let
          fixture = pkgs.writeText "bgp.conf" (lib.concatMapStrings
            (name: ''
              define ${name} = "fixture";
            '')
            (lib.unique (lib.catAttrs "value" (lib.catAttrs "password" bgp))));
        in
        ''
          cp ${fixture} bgp.conf
        '';

      sops.secrets.bgp = {
        # modules are copied to the store apart from hosts
        # the file need to be copied out of flake source on its own
        # also lib.path is nixpkgs path library (we need the primop here)
        sopsFile = builtins.path { path = "${inputs.self}/hosts/${config.networking.hostName}/secrets.yaml"; };
        mode = "440";
        owner = config.systemd.services.bird.serviceConfig.User;
        group = config.systemd.services.bird.serviceConfig.Group;
        reloadUnits = [ config.systemd.services.bird.name ];
      };

      services.bird.settings = {
        router-id = host.ipv4;
        include = [ "bgp.conf" ];
        template.bgp = {
          upstream4 = upstream "ipv4";
          upstream6 = upstream "ipv6";
        };
        protocol = {
          device.device0.scan-time = 10;
          direct.direct0 = {
            interface = [{ pattern = host.ipam.interface; }];
            ipv4 = { };
            ipv6 = { };
          };
          kernel = {
            kernel4 = {
              scan-time = 10;
              learn = true;
              persist = true;
              ipv4 = { import = "none"; export = "none"; };
            };
            kernel6 = {
              scan-time = 10;
              learn = true;
              persist = true;
              ipv6 = { import = "none"; export = "none"; };
            };
          };
          static = {
            static4 = {
              ipv4 = { };
              route = lib.map (route "ipv4") (lib.blueprint.net.ipam.ipv4 ++ experimental.ipv4);
            };
            static6 = {
              ipv6 = { };
              route = lib.map (route "ipv6") (lib.blueprint.net.ipam.ipv6 ++ experimental.ipv6);
            };
          };
        };
      };
    })
    {
      boot.kernelModules = [ "dummy" ];
      systemd.network.config.networkConfig.ManageForeignRoutes = false;

      systemd.network.netdevs."40-${host.ipam.interface}".netdevConfig = {
        Kind = "dummy";
        Name = host.ipam.interface;
      };

      systemd.network.networks."40-${host.ipam.interface}" = {
        name = host.ipam.interface;
        # unicast, and the personal site anycast on routers
        # ranet3 puts the ipam pair on its tun through cap.table.addresses
        address = lib.subtractLists
          (lib.optionals config.networking.ranet3.enable [ ipam.ipv4 ipam.ipv6 ])
          (addresses "ipv4" ++ addresses "ipv6");
        # bird's bgp sessions leave by main whatever the mesh's table holds for a neighbor
        # ranet3 reads its table for every lookup that main has no route longer than /0 for
        routingPolicyRules = lib.optionals (exit && config.networking.ranet3.enable) (lib.map
          (a: { From = a; Table = "main"; Priority = 5300; })
          (lib.unique ([ host.ipv4 host.ipv6 ] ++ lib.catAttrs "source-address" bgp)));
      };

      networking.nftables.tables = {
        outbound4 = {
          name = "nat";
          family = "ip";
          content = ''
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              ip saddr != { ${lib.concatStringsSep ", " (prefixes "ipv4")} } oifname "${host.interface}" masquerade
            }
          '';
        };
        outbound6 = {
          name = "nat";
          family = "ip6";
          content = ''
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              # a packet for the node's own uplink address leaves by the uplink only while that address is tentative
              # masquerading it binds the flow to lo's first global address for as long as the peer keeps sending
              ${lib.optionalString (host != null && host ? ipv6) "ip6 daddr ${host.ipv6} return"}
              ip6 saddr != { ${lib.concatStringsSep ", " (prefixes "ipv6")} } oifname "${host.interface}" masquerade
            }
          '';
        };

        # fix PMTU blackhole on the anycast overlay
        # client packets ingress over the 1400 MTU mesh
        # but an exit node SYN ACK egresses its native primary iface at 1500
        # so the kernel advertises a 1500 derived mss (1460 on the wire)
        # big segments (e.g. a post quantum TLS ClientHello) then overshoot the 1400 ingress and get undropped
        mssclamp =
          let
            mss = 1328; # 1400 - 20 - 20 - 12
            addrs = lib.concatMapStringsSep ", " (a: lib.head (lib.splitString "/" a));
            v4 = addresses "ipv4";
            v6 = addresses "ipv6";
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
    }
    (lib.mkIf exit {
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
        enable = config.services.bird.enable && config.services.victoriametrics.enable;
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
