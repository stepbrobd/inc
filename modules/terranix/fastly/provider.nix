{ lib, ... }:

lib.deepMergeAttrsList (
  with lib.terranix.provider;
  [
    cloudflare
    fastly
  ]
)
