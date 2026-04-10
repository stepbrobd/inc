{ lib }:

# expand abbv v6 addr to 8 groups and 4 digit per group
# "2602:f590::23:161:104:128"
# ->
# "2602:f590:0000:0000:0023:0161:0104:0128"
addr:
let
  parts = lib.splitString "::" addr;
  hasDoubleColon = lib.length parts == 2;

  left = lib.splitString ":" (lib.head parts);
  right = if hasDoubleColon then lib.splitString ":" (lib.last parts) else [ ];

  missing = 8 - lib.length left - lib.length right;
  zeros = lib.genList (_: "0000") missing;

  padGroup = g: lib.substring
    0
    (4 - (lib.stringLength g)) "0000"
  + g;

  groups =
    if hasDoubleColon
    then lib.map padGroup (left ++ zeros ++ right)
    else lib.map padGroup (lib.splitString ":" addr);
in
lib.concatStringsSep ":" groups
