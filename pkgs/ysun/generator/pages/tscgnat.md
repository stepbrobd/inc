---
title: De-escalating Tailscale CGNAT conflict
description: How to workaround Tailscale dropping the entire CGNAT range if you want to keep traffic to some addresses within CGNAT IPv4 range
created: 2025-11-01
updated: 2026-02-12
---

Originally posted as a comment to
[tailscale#1381](https://github.com/tailscale/tailscale/issues/1381#issuecomment-3476690745).

Since no one at Tailscale seem to care about this [^1], I spent some time trying
to hack together a "fix" inspired by another
[NixOS user](https://github.com/tailscale/tailscale/issues/1381#issuecomment-1945432578)
who also commented in the issue thread.

[^1]: I mentioned this issue on an official Tailscale Q&A YouTube live stream
    (can't find the link, sorry) a couple of months ago, the hosts mentioned
    there's a fix coming soon (I assume are talking about
    [`OneCGNAT`](https://tailscale.com/kb/1337/policy-syntax#onecgnatroute)),
    but you know... nothing happened. I also commented on
    ["The Tailscale Fall Update in under 8 minutes"](https://www.youtube.com/watch?v=GV8CVNd5nAI)
    asking the same question, but it was removed in less than a day.

Problem: my VPS provider allow BGP session with their router for BYOIP, but the
upstream router's IPv4 address is in CGNAT range (100.100.0.0) [^2]. Since
Tailscale automatically adds firewall rules to drop all traffic coming from
CGNAT range (something like
`oifname "tailscale0*" ip saddr 100.64.0.0/10 counter packets 0 bytes 0 drop` in
nftables, and there are rules matching on both `iifname` and `oifname`), my
routing daemon is unable to communicate with my upstream's router. Also given
that the IPv4 in question is in 100.100.0.0/24, it's impossible to (correctly)
split the full CGNAT range to get a valid CIDR from 100.100.1.0 to the end of
100.64/10 (I'll talk about why this requirement exists in the first place
later).

[^2]: Unfortunately, they don't have MP-BGP extension enabled :<, I tried it
    before messing with Tailscale.

## First try

[I tried to patch `net/tsaddr/tsaddr.go`](https://github.com/stepbrobd/dotfiles/commit/74f90a2330c717ffc955ef40ed93a408996b6f38)
like the other NixOS user did
[here](https://github.com/infinidoge/universe/commit/45e9fc405cf92a2f97b72e4b49a327377109a91d)
to hardcode the value of `CGNATRange` to `100.100.1.0/10` (incorrect CIDR) [^3].

[^3]: Maybe, just maybe, since these are both incorrect, `100.100.1.0/11` is a
    better choice? But it doesn't really matter here.

This did allow my local traffic to 100.100.0.0 to go through just fine, but the
generated ts-forward chain still contain 100.64/10:

```shell
table ip filter {
    chain ts-forward {
        iifname "tailscale0*" counter packets 23039 bytes 3167083 meta mark set meta mark & 0xffff04ff | 0x00000400
        meta mark & 0x0000ff00 == 0x00000400 counter packets 23039 bytes 3167083 accept
        #                             full CGNAT range
        oifname "tailscale0*" ip saddr 100.64.0.0/10 counter packets 0 bytes 0 drop
        #                              ^^^^^^^^^^^^^
        oifname "tailscale0*" counter packets 24402 bytes 1876250 accept
    }

    chain ts-input {
        iifname "lo*" ip saddr 100.100.20.4 counter packets 0 bytes 0 accept
        iifname != "tailscale0*" ip saddr 100.115.92.0/23 counter packets 0 bytes 0 return
        #                              this is what i wanted
        iifname != "tailscale0*" ip saddr 100.100.1.0/10 counter packets 0 bytes 0 drop
        #                                 ^^^^^^^^^^^^^^
        iifname "tailscale0*" counter packets 64279 bytes 11001967 accept
        udp dport 41641 counter packets 71882 bytes 9712512 accept
    }
}
```

The reason why `ts-input` chain got the patched CGNAT range but not `ts-forward`
chain did not is caused by a "bug" (not exactly?) in
`util/linuxfw/nftables_runner.go`.

The code for nftables rule generation for `ts-input` chain is not normalized
(reading `tsaddr.CGNATRange()` would spit out the patched `netip.Prefix`):

```go
// https://github.com/tailscale/tailscale/blob/db7dcd516f7da6792cd4fa44b97bc510102941c5/util/linuxfw/nftables_runner.go#L1214
// addDropCGNATRangeRule adds a rule to drop if the source IP is in the
// CGNAT range.
func addDropCGNATRangeRule(c *nftables.Conn, table *nftables.Table, chain *nftables.Chain, tunname string) error {
	rule, err := createRangeRule(table, chain, tunname, tsaddr.CGNATRange(), expr.VerdictDrop)
//                                                      ^^^^^^^^^^^^^^^^^^^
// ...                                                  netip.Prefix
```

Whereas rule generation for `ts-forward` is normalized by the call of
[netip.Prefix.String](https://pkg.go.dev/net/netip#Prefix.String)
(`tsaddr.CGNATRange().String()` would get `"100.64.0.0/10"`) resulting in the
correct but not what we wanted full CGNAT range:

```go
// https://github.com/tailscale/tailscale/blob/db7dcd516f7da6792cd4fa44b97bc510102941c5/util/linuxfw/nftables_runner.go#L1279
// createDropOutgoingPacketFromCGNATRangeRuleWithTunname creates a rule to drop
// outgoing packets from the CGNAT range.
func createDropOutgoingPacketFromCGNATRangeRuleWithTunname(table *nftables.Table, chain *nftables.Chain, tunname string) (*nftables.Rule, error) {
	_, ipNet, err := net.ParseCIDR(tsaddr.CGNATRange().String())
//                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ...                             netip.Prefix   ->   string
```

In theory, I could just get rid of the normalization and put `"100.100.1.0/10"`
there and get what I wanted but I'm already here :<, why not just go along with
the momentum...

## Second try

In my opinion, the firewall rule generation code here is a bit less than
optimal. If the drop rule takes lets say, a slice of `netip.Prefix` (v.s. the
hardcoded CGNAT range), this issue
([tailscale#1381](https://github.com/tailscale/tailscale/issues/1381)) won't
even be here in the first place as implementing per-host /32 drop rules would be
trivial. Since changing all the pre-existing usage on `tsaddr.CGNATRange()`
would result in a huge patch, I switched side and aimed for the opposite end,
creating exceptions for addresses I don't want packets to be dropped.

Basically Tailscale uses
[Google's nftables library](https://github.com/google/nftables) in
`util/linuxfw/iptables_runner.go` to programmatically generate rules, so
[I just need to inject the exception for IP addresses I see fit before the `drop` verdict](https://github.com/stepbrobd/dotfiles/commit/5248f65c1d30348037a72fe9c41686a32366ed17).

In the original code responsible for generating `ts-forward` chain:

```go
// createDropOutgoingPacketFromCGNATRangeRuleWithTunname creates a rule to drop
// outgoing packets from the CGNAT range.
func createDropOutgoingPacketFromCGNATRangeRuleWithTunname(table *nftables.Table, chain *nftables.Chain, tunname string) (*nftables.Rule, error) {
	_, ipNet, err := net.ParseCIDR(tsaddr.CGNATRange().String())
	if err != nil {
		return nil, fmt.Errorf("parse cidr: %v", err)
	}
	mask, err := hex.DecodeString(ipNet.Mask.String())
	if err != nil {
		return nil, fmt.Errorf("decode mask: %v", err)
	}
	netip := ipNet.IP.Mask(ipNet.Mask).To4()
	saddrExpr, err := newLoadSaddrExpr(nftables.TableFamilyIPv4, 1)
	if err != nil {
		return nil, fmt.Errorf("newLoadSaddrExpr: %v", err)
	}
	rule := &nftables.Rule{
		Table: table,
		Chain: chain,
		Exprs: []expr.Any{
			&expr.Meta{Key: expr.MetaKeyOIFNAME, Register: 1},
			&expr.Cmp{
				Op:       expr.CmpOpEq,
				Register: 1,
				Data:     []byte(tunname),
			},
			saddrExpr,
			&expr.Bitwise{
				SourceRegister: 1,
				DestRegister:   1,
				Len:            4,
				Mask:           mask,
				Xor:            []byte{0x00, 0x00, 0x00, 0x00},
			},
			&expr.Cmp{
				Op:       expr.CmpOpEq,
				Register: 1,
				Data:     netip,
			},
			&expr.Counter{},
			&expr.Verdict{
				Kind: expr.VerdictDrop,
			},
		},
	}
	return rule, nil
}
```

`rule.Exprs` have this structure:

```txt
0: Meta (`oifname`)
1: Cmp (check interface == tunname)
2: Payload (`ip saddr`)
3: Bitwise (parsed beforehand, before patch it would be `255.192.0.0` for `/10`)
4: Cmp (compare if `ip saddr` is in `netip` combined with `mask` loaded above, before patch it would be `100.64.0.0`)
5: Counter
6: Verdict (drop)
```

And we would want the injection to look like this:

```txt
... # same as 1-4 above
5: Payload (`ip saddr`)
6. Bitwise (netmask for CIDR that we want to ignore)
7. Cmp (compare if `ip saddr` is not in excluded IP combined with netmast loaded in the previous step)
... # same as 5-6 above
```

In implementation:

```diff
diff --git c/util/linuxfw/nftables_runner.go i/util/linuxfw/nftables_runner.go
index faa02f7c7..e0eafef7d 100644
--- c/util/linuxfw/nftables_runner.go
+++ i/util/linuxfw/nftables_runner.go
@@ -1274,7 +1274,7 @@ func addSetSubnetRouteMarkRule(c *nftables.Conn, table *nftables.Table, chain *n
 }
 
 // createDropOutgoingPacketFromCGNATRangeRuleWithTunname creates a rule to drop
-// outgoing packets from the CGNAT range.
+// outgoing packets from the CGNAT range, excluding 100.100.0.0/24.
 func createDropOutgoingPacketFromCGNATRangeRuleWithTunname(table *nftables.Table, chain *nftables.Chain, tunname string) (*nftables.Rule, error) {
 	_, ipNet, err := net.ParseCIDR(tsaddr.CGNATRange().String())
 	if err != nil {
@@ -1285,10 +1285,14 @@ func createDropOutgoingPacketFromCGNATRangeRuleWithTunname(table *nftables.Table
 		return nil, fmt.Errorf("decode mask: %v", err)
 	}
 	netip := ipNet.IP.Mask(ipNet.Mask).To4()
+
+	excludeNet := net.ParseIP("100.100.0.0").To4()
+	excludeMask := net.IPv4Mask(255, 255, 255, 0)
 	saddrExpr, err := newLoadSaddrExpr(nftables.TableFamilyIPv4, 1)
 	if err != nil {
 		return nil, fmt.Errorf("newLoadSaddrExpr: %v", err)
 	}
+
 	rule := &nftables.Rule{
 		Table: table,
 		Chain: chain,
@@ -1312,6 +1316,19 @@ func createDropOutgoingPacketFromCGNATRangeRuleWithTunname(table *nftables.Table
 				Register: 1,
 				Data:     netip,
 			},
+			saddrExpr,
+			&expr.Bitwise{
+				SourceRegister: 1,
+				DestRegister:   1,
+				Len:            4,
+				Mask:           excludeMask,
+				Xor:            []byte{0x00, 0x00, 0x00, 0x00},
+			},
+			&expr.Cmp{
+				Op:       expr.CmpOpNeq,
+				Register: 1,
+				Data:     excludeNet,
+			},
 			&expr.Counter{},
 			&expr.Verdict{
 				Kind: expr.VerdictDrop,
```

The same idea apply to the function handling `ts-input` chain. In the end, we
can get a Tailscale to play nice with other hosts with CGNAT IP addresses:

```shell
table ip filter {
    chain ts-forward {
        iifname "tailscale0*" counter packets 355 bytes 91872 meta mark set meta mark & 0xffff04ff | 0x00000400
        meta mark & 0x0000ff00 == 0x00000400 counter packets 355 bytes 91872 accept
        #                              full CGNAT    injected exception
        oifname "tailscale0*" ip saddr 100.64.0.0/10 ip saddr != 100.100.0.0/24 counter packets 0 bytes 0 drop
        #                              ^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^
        oifname "tailscale0*" counter packets 56 bytes 2792 accept
    }

    chain ts-input {
        iifname "lo*" ip saddr 100.100.20.4 counter packets 0 bytes 0 accept
        iifname != "tailscale0*" ip saddr 100.115.92.0/23 counter packets 0 bytes 0 return
        #                                 full CGNAT    injected exception
        iifname != "tailscale0*" ip saddr 100.64.0.0/10 ip saddr != 100.100.0.0/24 counter packets 0 bytes 0 drop
        #                                 ^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^
        iifname "tailscale0*" counter packets 120 bytes 31189 accept
        udp dport 41641 counter packets 2104 bytes 516242 accept
    }
}
```

Ignoring the hardcoded CIDR, I think this could be used to implement another ACL
derivative like `DontDropTheseCIDR` and map to a list of CIDRs that could
actually get
[tailscale#1381](https://github.com/tailscale/tailscale/issues/1381) closed.
