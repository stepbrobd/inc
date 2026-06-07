{ config, lib, modulesFor, self, ... }:

{
  flake.terranixModules = modulesFor "terranix";

  perSystem = { pkgs, self', system, ... }: {
    packages.terranixConfiguration =
      let
        inherit system;
        modules = lib.attrValues config.flake.terranixModules;
      in
      (lib.terranixConfiguration {
        inherit system modules;
      }).overrideAttrs {
        passthru = {
          inherit (lib.terranixConfigurationAst {
            inherit system modules;
          }) config;
        };
      };

    apps.terranix = {
      type = "app";
      program = pkgs.writeShellApplication {
        name = "terranix";

        runtimeInputs = with pkgs; [
          gnused
          sops
          opentofu
        ];

        text = ''
          rm -f config.tf.json .terraform.lock.hcl
          cp ${self'.packages.terranixConfiguration} config.tf.json

          if [[ -v GARNIX_CI ]]; then 
            export SOPS_AGE_KEY_FILE="$GARNIX_ACTION_PRIVATE_KEY_FILE"
            pushd ${self.outPath} && popd # depend on flake source root
          fi
          eval "$(sops decrypt --extract '["cloudflare"]["backend"]["export"]' ${../../../lib/terranix/secrets.yaml})"

          tofu init
          tofu apply -auto-approve

          rm -f config.tf.json .terraform.lock.hcl
        '';
      };
    };
  };
}
