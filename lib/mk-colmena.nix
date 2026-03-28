{ lib }:

let
  inherit (lib) genHostModules;
in
{ inputs
, os
, hosts ? { } # { "x86_64-linux" = [ "host1" ]; "aarch64-linux" = [ "host2" ]; }
, users ? { } # { "username" -> [ module ] }
, modules ? [ ] # nixos/darwin modules
, nixpkgs # raw nixpkgs flake input
, getSystem # platform -> perSystem attrset
, specialArgs ? { }
}:

let
  # invert { platform -> [ hosts ] } to { host -> platform }
  hostPlatforms = lib.mergeAttrsList (lib.mapAttrsToList
    (platform: hostList: lib.genAttrs hostList (_: platform))
    hosts);

  allHostNames = lib.attrNames hostPlatforms;
in
{
  meta = {
    # only used for colmena bootstrapping (lib, eval-config.nix path);
    # each node's actual pkgs comes from nodeNixpkgs
    nixpkgs = import nixpkgs { system = "x86_64-linux"; };

    nodeNixpkgs = lib.mapAttrs
      (_: platform: (getSystem platform).allModuleArgs.pkgs)
      hostPlatforms;

    # nodeSpecialArgs not needed
    inherit specialArgs;
  };
} // lib.genAttrs allHostNames (host: {
  imports =
    let
      platform = hostPlatforms.${host};
      entrypoint = "${inputs.self}/hosts/server/${host}";
    in
    genHostModules
      {
        inherit inputs os platform entrypoint users modules specialArgs;
      } ++ [
      (
        { config, ... }:
        {
          deployment =
            {
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
