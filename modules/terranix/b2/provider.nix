{ lib, ... }:

lib.deepMergeAttrsList (
  with lib.terranix.provider;
  [
    b2
  ]
)
