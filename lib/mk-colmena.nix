{ lib }:

let
  inherit (lib) attrNames genAttrs genHostModules map mapAttrs mergeAttrsList;
in
{ inputs
, hosts ? [ ] # [ { os, platform, modules, users, names } ]
, nixpkgs # raw nixpkgs flake input
, nix-darwin ? null # nix-darwin flake input
, getSystem # platform -> perSystem attrset
, specialArgs ? { }
}:

let
  # flatten groups into { host -> { os, platform, modules, users } }
  hostConfigs = mergeAttrsList (map
    (group: genAttrs group.names (_: {
      inherit (group) os platform modules users;
    }))
    hosts);

  allHostNames = attrNames hostConfigs;
in
{
  meta = {
    # only used for colmena bootstrapping (lib, eval-config.nix path);
    # each node's actual pkgs comes from nodeNixpkgs
    nixpkgs = import nixpkgs { system = "x86_64-linux"; };
    # for darwin deployment
    inherit nix-darwin;

    nodeNixpkgs = mapAttrs
      (_: cfg: (getSystem cfg.platform).allModuleArgs.pkgs)
      hostConfigs;

    inherit specialArgs;
  };
} // genAttrs allHostNames (host:
  let
    cfg = hostConfigs.${host};
    entrypoint = "${inputs.self}/hosts/${host}";
  in
  {
    # at hive node top-level so getNodeSystemType can detect it before evaluation
    deployment.systemType = cfg.os;

    imports =
      genHostModules
        {
          inherit inputs specialArgs entrypoint;
          inherit (cfg) os platform modules users;
        } ++ [
        (
          { config, ... }:
          {
            deployment =
              {
                # yolo
                allowLocalDeployment = true;

                targetUser = null;
                targetHost = "${config.networking.hostName}.${lib.blueprint.tailscale.tailnet}";

                # fix hanging issue
                sshOptions = [
                  "-o"
                  "ConnectTimeout=10"
                  "-o"
                  "ControlMaster=auto"
                  "-o"
                  "ServerAliveCountMax=3"
                  "-o"
                  "ServerAliveInterval=10"
                  "-o"
                  "TCPKeepAlive=no"
                ];

                # inherit all the tags so its easier to filter
                tags =
                  let
                    bp = lib.blueprint.hosts.${config.networking.hostName} or null;
                  in
                  if bp != null then bp.tags else [ ];
              };
          }
        )
      ];
  })
