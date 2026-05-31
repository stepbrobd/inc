{ lib }:

# convert a zone name to its resource slug ("-"/"." -> "_")
# "ysun.co"                  -> "co_ysun"
# "136.104.192.in-addr.arpa" -> "arpa_in_addr_192_104_136"
zone:
lib.replaceStrings [ "-" ] [ "_" ]
  (lib.concatStringsSep "_" (lib.reverseList (lib.splitString "." zone)))
