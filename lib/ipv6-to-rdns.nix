{ lib }:

# convert v6 address to rdns (full form with .ip6.arpa suffix)
# "2602:f590::23:161:104:128"
# ->
# "8.2.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0.0.0.9.5.f.2.0.6.2.ip6.arpa"
addr:
let
  expanded = lib.expandIpv6 addr;
  hex = lib.replaceStrings [ ":" ] [ "" ] expanded;
  nibbles = lib.stringToCharacters hex;
  reversed = lib.reverseList nibbles;
in
lib.concatStringsSep "." reversed + ".ip6.arpa"
