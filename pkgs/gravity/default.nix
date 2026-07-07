{ lib
, formats
, writeShellScriptBin
, iproute2
, gnugrep
, gawk
, coreutils
}:

let
  bp = lib.blueprint;

  # routes all traffic (v4+v6) thru mesh sourced from THIS node's announced ip
  # discovered at runtime from dummy0 (excluding the anycast ips)
  # exiting at babel selected node
  vpn = writeShellScriptBin "gv" ''
    set -u

    export PATH=${lib.makeBinPath [ iproute2 gnugrep gawk coreutils ]}
    port=${toString bp.ranet.port}

    anycast4=23.161.104.17
    anycast6=2602:f590::23:161:104:17

    dev=dummy0

    t=210
    v4=$(ip -4 -o addr show dev "$dev" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | grep -vxF "$anycast4" | head -1)
    v6=$(ip -6 -o addr show dev "$dev" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | grep -vxF "$anycast6" | head -1)

    clear() {
      for f in -4 -6; do
        for p in 5290 5299 5300; do ip $f rule del pref "$p" 2>/dev/null || true; done
        ip $f route flush table "$t" 2>/dev/null || true
      done
    }

    case "''${1:-}" in
      on)
        [ -n "$v4$v6" ] || { echo "gv: no mesh source on $dev (is the gravity mesh up?)" >&2; exit 1; }
        clear
        ip -4 rule add pref 5290 ipproto udp dport "$port" lookup main
        ip -6 rule add pref 5290 ipproto udp dport "$port" lookup main
        [ -n "$v4" ] && ip -4 route replace default dev gravity src "$v4" table "$t"
        [ -n "$v6" ] && ip -6 route replace default dev gravity src "$v6" table "$t"
        ip -4 rule add pref 5299 lookup main suppress_prefixlength 0
        ip -6 rule add pref 5299 lookup main suppress_prefixlength 0
        ip -4 rule add pref 5300 lookup "$t"
        ip -6 rule add pref 5300 lookup "$t"
        echo "gv ON: v4+v6 -> gravity mesh (src ''${v4:-none} / ''${v6:-none}, babel-selected exit)"
        ;;
      off)
        clear
        echo "gv OFF: -> direct"
        ;;
      status)
        if ip -4 rule | grep -q '5300:'; then echo "gv: ON (src ''${v4:-none} / ''${v6:-none})"; else echo "gv: OFF"; fi
        ;;
      *)
        echo "usage: sudo gv {on|off|status}"; exit 1 ;;
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
