{ terraform-providers }:

(terraform-providers.mkProvider {
  owner = "stepbrobd";
  repo = "terraform-provider-arin";
  rev = "v2026.1026.0";
  hash = "sha256-KtBHdHEpAp8EcoErNWvKR67TxeII7zTUunfVVnWErpY=";
  vendorHash = "sha256-WiN88BAT9ABtmPPoeSXjIud/MwJEmSCTQQeo7Vf5BQE=";
  spdx = "MIT";
  provider-source-address = "registry.terraform.io/stepbrobd/arin";
}).overrideAttrs { subPackages = [ "cmd/terraform-provider-arin" ]; }
