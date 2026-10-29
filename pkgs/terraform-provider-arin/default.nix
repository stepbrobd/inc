{ terraform-providers }:

(terraform-providers.mkProvider {
  owner = "stepbrobd";
  repo = "terraform-provider-arin";
  rev = "v2026.1026.0";
  hash = "sha256-KtBHdHEpAp8EcoErNWvKR67TxeII7zTUunfVVnWErpY=";
  vendorHash = "sha256-WiN88BAT9ABtmPPoeSXjIud/MwJEmSCTQQeo7Vf5BQE=";
  spdx = "MIT";
  provider-source-address = "registry.terraform.io/stepbrobd/arin";
}).overrideAttrs (prev: {
  subPackages = [ "cmd/terraform-provider-arin" ];
  passthru = (prev.passthru or { }) // {
    autobump = true;
    autobumpArgs = [ "--override-filename" "pkgs/terraform-provider-arin/default.nix" ];
    updateScript = null;
  };
})
