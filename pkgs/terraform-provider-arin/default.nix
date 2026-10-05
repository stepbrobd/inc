{ terraform-providers }:

(terraform-providers.mkProvider {
  owner = "stepbrobd";
  repo = "terraform-provider-arin";
  rev = "v2026.1005.1";
  hash = "sha256-yduHq+uDBwABIrXjv8Fzdhx8FLr3vx43YnDYK3E7ELA=";
  vendorHash = "sha256-WiN88BAT9ABtmPPoeSXjIud/MwJEmSCTQQeo7Vf5BQE=";
  spdx = "MIT";
  provider-source-address = "registry.terraform.io/stepbrobd/arin";
}).overrideAttrs { subPackages = [ "cmd/terraform-provider-arin" ]; }
