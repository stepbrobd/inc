{ lib }:

# convert v4 address to rdns (with .in-addr.arpa suffix)
# "23.161.104.128"
# ->
# "128.104.161.23.in-addr.arpa"
addr:
lib.concatStringsSep
  "."
  (lib.reverseList (lib.splitString "." addr))
  +
".in-addr.arpa"
