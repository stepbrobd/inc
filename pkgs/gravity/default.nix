# gv depends on the SID and policy-routing contract in modules/nixos/ranet.nix
# keep SID suffixes, tables, priorities, and firewall hooks synchronized

{ lib
, formats
, writeShellScriptBin
, writeText
, iproute2
, gnugrep
, gawk
, coreutils
, nftables
}:

let
  bp = lib.blueprint;

  # nodes with a gravity /60 publish srv6 sids in the "6" nibble subspace (modules/nixos/ranet.nix)
  #   <base>6::2 End, transit waypoint, every server
  #   <base>6::3 End.DT46 into the egress vrf with snat to the node ipam address, bgp exits only
  srv6Nodes = lib.filter (h: lib.hasSuffix "0::/60" h.ranet.gravity.prefix)
    (lib.collect (h: h ? ranet && h.ranet ? gravity) bp.hosts);
  sidStem = h: "${lib.removeSuffix "0::/60" h.ranet.gravity.prefix}6";
  transitNodes = lib.filter (h: h.type == "server") srv6Nodes;
  exitNodes = lib.filter (h: h.type == "server" && lib.elem "router" h.tags) srv6Nodes;
  names = lib.concatMapStringsSep " " (h: h.hostName);
  cases = sid: lib.concatMapStringsSep "\n" (h: "        ${h.hostName}) echo ${sidStem h}::${sid} ;;");

  # replies to node local srv6 flows arrive ct invalid, seg6 output discards the unconfirmed
  # conntrack entry, and the nixos-fw input chain drops them before any other chain runs
  # remember the tuples this node sends into the mesh and accept exactly their replies
  # conntrack picks the flow up from the first accepted reply, so the entries can be short lived
  replyRules = writeText "gv-reply.nft" ''
    table inet nixos-fw {
      set gv4 {
        type ipv4_addr . inet_proto . inet_service . inet_service
        flags dynamic,timeout
        timeout 5m
      }
      set gv6 {
        type ipv6_addr . inet_proto . inet_service . inet_service
        flags dynamic,timeout
        timeout 5m
      }
      chain gv-output {
        type filter hook output priority filter; policy accept;
        oifname "gravity" meta l4proto { tcp, udp } update @gv4 { ip daddr . meta l4proto . th dport . th sport }
        oifname "gravity" meta l4proto { tcp, udp } update @gv6 { ip6 daddr . meta l4proto . th dport . th sport }
      }
    }
  '';

  # routes all traffic (v4+v6) thru mesh sourced from THIS node's announced ip
  # discovered at runtime from dummy0 (excluding the anycast ips)
  # exiting at babel selected node, or with --to at a named bgp exit using that node's ip,
  # optionally via --transit waypoints (srv6 segment list, node names from lib.blueprint)
  vpn = writeShellScriptBin "gv" ''
    set -Eeuo pipefail

    export PATH=${lib.makeBinPath [ iproute2 gnugrep gawk coreutils nftables ]}
    port=${toString bp.ranet.port}

    anycast4=23.161.104.17
    anycast6=2602:f590::23:161:104:17

    source_device=dummy0
    state_dir=/run/gv
    route_table=210
    mesh_table=ranet
    setup_active=0

    usage() {
      echo "usage: sudo gv {on [--transit node,node,...] [--to exit]|off|status}" >&2
    }

    die() {
      echo "gv: $*" >&2
      exit 1
    }

    first_global_address() {
      local family=$1 device=$2 excluded=''${3:-}
      ip "$family" -o addr show dev "$device" scope global 2>/dev/null |
        awk -v excluded="$excluded" '{
          address = $4
          sub(/\/.*/, "", address)
          if (!found && address != excluded) {
            print address
            found = 1
          }
        }'
    }

    v4=$(first_global_address -4 "$source_device" "$anycast4") || v4=""
    v6=$(first_global_address -6 "$source_device" "$anycast6") || v6=""

    transit_sid() {
      case "$1" in
    ${cases "2" transitNodes}
        *) echo "gv: no transit sid for '$1' (servers: ${names transitNodes})" >&2; return 1 ;;
      esac
    }

    exit_sid() {
      case "$1" in
    ${cases "3" exitNodes}
        *) echo "gv: no exit sid for '$1' (bgp exits: ${names exitNodes})" >&2; return 1 ;;
      esac
    }

    reply_accept_on() {
      nft list table inet nixos-fw >/dev/null 2>&1 || {
        echo "gv: no inet nixos-fw table, replies are not filtered" >&2
        return 0
      }
      nft -f ${replyRules}
      nft insert rule inet nixos-fw input iifname "gravity" ip saddr . meta l4proto . th sport . th dport @gv4 accept comment '"gv-reply"'
      nft insert rule inet nixos-fw input iifname "gravity" ip6 saddr . meta l4proto . th sport . th dport @gv6 accept comment '"gv-reply"'
      nft insert rule inet nixos-fw input iifname "gravity" icmp type '{ echo-reply, destination-unreachable, time-exceeded }' accept comment '"gv-reply"'
      nft insert rule inet nixos-fw input iifname "gravity" icmpv6 type '{ echo-reply, destination-unreachable, packet-too-big, time-exceeded }' accept comment '"gv-reply"'
    }

    reply_accept_off() {
      nft list table inet nixos-fw >/dev/null 2>&1 || return 0
      while read -r handle; do
        [ -n "$handle" ] && nft delete rule inet nixos-fw input handle "$handle" || true
      done < <(
        nft -a list chain inet nixos-fw input |
          grep '"gv-reply"' |
          grep -oE 'handle [0-9]+' |
          awk '{print $2}'
      )
      nft delete chain inet nixos-fw gv-output 2>/dev/null || true
      nft delete set inet nixos-fw gv4 2>/dev/null || true
      nft delete set inet nixos-fw gv6 2>/dev/null || true
    }

    disable() {
      for family in -4 -6; do
        for priority in 148 149 5290 5299 5300; do
          while ip "$family" rule del pref "$priority" 2>/dev/null; do :; done
        done
        ip "$family" route flush table "$route_table" 2>/dev/null || true
      done
      reply_accept_off
      if [ -e "$state_dir/tunsrc" ]; then
        ip sr tunsrc set :: 2>/dev/null || true
        rm -f "$state_dir/tunsrc" 2>/dev/null || true
      fi
      rm -f "$state_dir/mode" 2>/dev/null || true
      rmdir "$state_dir" 2>/dev/null || true
    }

    finish() {
      local status=$?
      trap - EXIT
      if [ "$setup_active" -eq 1 ]; then
        disable
        echo "gv: setup failed; restored direct routing" >&2
      fi
      exit "$status"
    }
    trap finish EXIT

    rule_matches() {
      local family=$1 priority=$2 expected=$3
      ip "$family" rule show pref "$priority" 2>/dev/null | grep -qF "$expected"
    }

    default_route_exists() {
      ip "$1" route show table "$route_table" default 2>/dev/null | grep -q '^default '
    }

    srv6_default_route_exists() {
      ip "$1" route show table "$route_table" default 2>/dev/null | grep -qF 'encap seg6'
    }

    state_complete() {
      local mode=$1 family
      [ -n "$mode" ] || return 1
      for family in -4 -6; do
        rule_matches "$family" 5290 "ipproto udp sport $port lookup main" || return 1
        rule_matches "$family" 5299 "lookup main suppress_prefixlength 0" || return 1
        rule_matches "$family" 5300 "lookup $route_table" || return 1
      done
      [ -z "$v4" ] || default_route_exists -4 || return 1
      [ -z "$v6" ] || default_route_exists -6 || return 1
      case "$mode" in
        srv6*)
          [ -z "$v4" ] || srv6_default_route_exists -4 || return 1
          [ -z "$v6" ] || srv6_default_route_exists -6 || return 1
          [ -z "$v4" ] || rule_matches -4 148 "lookup $mesh_table suppress_prefixlength 0" || return 1
          [ -z "$v4" ] || rule_matches -4 149 "lookup $route_table" || return 1
          [ -z "$v6" ] || rule_matches -6 148 "lookup $mesh_table suppress_prefixlength 0" || return 1
          [ -z "$v6" ] || rule_matches -6 149 "lookup $route_table" || return 1
          [ "$(ip sr tunsrc show | awk '{print $3}')" != "::" ] || return 1
          if nft list table inet nixos-fw >/dev/null 2>&1; then
            nft list chain inet nixos-fw gv-output >/dev/null 2>&1 || return 1
          fi
          ;;
      esac
    }

    state_present() {
      [ -e "$state_dir/mode" ] ||
        ip -4 rule show pref 5300 2>/dev/null | grep -q . ||
        ip -6 rule show pref 5300 2>/dev/null | grep -q .
    }

    case "''${1:-}" in
      on)
        shift
        transit=""
        exit_node=""
        while [ $# -gt 0 ]; do
          case "$1" in
            --transit)
              [ $# -ge 2 ] || die "--transit needs a node list"
              [ -z "$transit" ] || die "--transit was given more than once"
              [ -n "$2" ] || die "--transit needs a node list"
              transit=$2
              shift 2
              ;;
            --to)
              [ $# -ge 2 ] || die "--to needs a node"
              [ -z "$exit_node" ] || die "--to was given more than once"
              [ -n "$2" ] || die "--to needs a node"
              exit_node=$2
              shift 2
              ;;
            *)
              usage
              exit 1
              ;;
          esac
        done
        [ -z "$transit" ] || [ -n "$exit_node" ] || die "--transit needs --to"
        [ -n "$v4$v6" ] || die "no mesh source on $source_device (is the gravity mesh up?)"

        transit_nodes=()
        segment_sids=()
        if [ -n "$transit" ]; then
          case "$transit" in
            ,* | *, | *,,*) die "--transit contains an empty node name" ;;
          esac
          IFS=, read -r -a transit_nodes <<< "$transit"
          for node in "''${transit_nodes[@]}"; do
            sid=$(transit_sid "$node") || exit 1
            segment_sids+=("$sid")
          done
        fi
        if [ -n "$exit_node" ]; then
          sid=$(exit_sid "$exit_node") || exit 1
          segment_sids+=("$sid")
        fi

        mode=native
        segs=""
        src6=""
        mtu=""
        segment_count=''${#segment_sids[@]}
        if [ "$segment_count" -gt 0 ]; then
          src6=$(first_global_address -6 gravity "") ||
            die "no global address on gravity for the outer source"
          [ -n "$src6" ] || die "no global address on gravity for the outer source"
          link_mtu=$(
            ip -o link show master gravity type xfrm 2>/dev/null |
              awk 'match($0, /mtu ([0-9]+)/, fields) {
                if (!minimum || fields[1] < minimum) minimum = fields[1]
              }
              END {
                if (minimum) print minimum
                else exit 1
              }'
          ) || die "no XFRM link in the gravity mesh"
          # remote legs can have a cached PMTU just below the local XFRM MTU
          mtu=$((link_mtu - 8))
          srh_overhead=$((48 + 16 * segment_count))
          [ $((mtu - srh_overhead)) -ge 1280 ] ||
            die "too many segments for XFRM MTU $link_mtu"
          segs=$(IFS=,; echo "''${segment_sids[*]}")
          mode="srv6 ''${transit:+transit=$transit }exit=$exit_node segs=$segs"
        fi

        disable
        mkdir -p "$state_dir"
        setup_active=1

        # strongSwan sends from the configured NAT-T port; peer NAT can change its destination port
        ip -4 rule add pref 5290 ipproto udp sport "$port" lookup main
        ip -6 rule add pref 5290 ipproto udp sport "$port" lookup main

        if [ "$segment_count" -eq 0 ]; then
          [ -z "$v4" ] || ip -4 route replace default dev gravity src "$v4" table "$route_table"
          [ -z "$v6" ] || ip -6 route replace default dev gravity src "$v6" table "$route_table"
        else
          if [ "$(ip sr tunsrc show | awk '{print $3}')" = "::" ]; then
            ip sr tunsrc set "$src6"
            touch "$state_dir/tunsrc"
          fi
          # the kernel subtracts the outer IPv6 and SRH headroom from this route MTU
          [ -z "$v4" ] || ip -4 route replace default encap seg6 mode encap segs "$segs" dev gravity src "$v4" mtu "$mtu" table "$route_table"
          [ -z "$v6" ] || ip -6 route replace default encap seg6 mode encap segs "$segs" dev gravity src "$v6" mtu "$mtu" table "$route_table"
          # pref 150 captures source-bound lookups, so table 210 must precede it
          # the suppressed table 200 lookup keeps mesh-internal routes on Babel
          [ -z "$v4" ] || {
            ip -4 rule add pref 148 from "$v4" lookup "$mesh_table" suppress_prefixlength 0
            ip -4 rule add pref 149 from "$v4" lookup "$route_table"
          }
          [ -z "$v6" ] || {
            ip -6 rule add pref 148 from "$v6" lookup "$mesh_table" suppress_prefixlength 0
            ip -6 rule add pref 149 from "$v6" lookup "$route_table"
          }
          reply_accept_on
        fi

        ip -4 rule add pref 5299 lookup main suppress_prefixlength 0
        ip -6 rule add pref 5299 lookup main suppress_prefixlength 0
        ip -4 rule add pref 5300 lookup "$route_table"
        ip -6 rule add pref 5300 lookup "$route_table"
        echo "$mode" > "$state_dir/mode"
        setup_active=0
        echo "gv ON: v4+v6 -> gravity mesh (src ''${v4:-none} / ''${v6:-none}, $mode)"
        ;;
      off)
        disable
        echo "gv OFF: -> direct"
        ;;
      status)
        mode=$(cat "$state_dir/mode" 2>/dev/null || true)
        if state_complete "$mode"; then
          echo "gv: ON $mode (src ''${v4:-none} / ''${v6:-none})"
        elif state_present; then
          echo "gv: STALE ''${mode:-mode-unknown} (src ''${v4:-none} / ''${v6:-none})"
          exit 1
        else
          echo "gv: OFF"
        fi
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  '';

  registry = {
    public_key = lib.trim bp.ranet.publicKey;
    organization = bp.ranet.organization;

    nodes = lib.map
      (h: {
        common_name = h.hostName;
        endpoints = h.ranet.endpoints;
        remarks = {
          prefix = h.ranet.gravity.prefix or null;
          region = with h.meta; "${city}, ${country}";
          provider = h.providerName;
          extensions =
            let
              base = lib.removeSuffix "0::/60" (h.ranet.gravity.prefix or "");
              hasPrefix = h ? ranet && h.ranet ? gravity && lib.hasSuffix "0::/60" h.ranet.gravity.prefix;
            in
            # server only
              # segment routing SIDs at the "6" nibble subspace
              # ::1 = End.DT46 (exit here)
              # ::2 = End (transit waypoint)
            lib.optional (hasPrefix && h.type == "server") {
              type = "srv6";
              enabled = true;
              addresses = [ "${base}6::1" "${base}6::2" ];
            };
        };
      })
      (lib.collect
        (h: h ? ranet && h.ranet ? endpoints && (lib.length h.ranet.endpoints) > 0)
        bp.hosts);
  };
in
((formats.json { }).generate "gravity.json" registry).overrideAttrs {
  passthru = { inherit registry vpn; full = ./secrets.yaml; };
}
