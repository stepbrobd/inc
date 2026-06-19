{ lib }:

{ inputs
, os
, specialArgs ? { }
, users ? { } # { "username" -> [ module ] }
}:

let
  inherit (lib) attrNames genAttrs map;

  usernames = attrNames users;
in
map (u: "${inputs.self}/users/${u}") usernames ++ [
  inputs.hm."${os}Modules".home-manager
  {
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users = genAttrs usernames (u: {
      imports = [
        # index
        inputs.index.homeModules.nix-index
        # secrets
        inputs.sops.homeManagerModules.sops
        { sops.defaultSopsFile = ./secrets.yaml; }
        ({ config, ... }: { sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt"; })
        # actual user module
        # so this was defined under
        # "${inputs.self}/users/${u}/home.nix"
        # but i feel like user level hm modules are better fully modulized
        # so we are directly injecting defaults here based on passed username
        ({ pkgs, ... }: {
          home = {
            username = u;
            homeDirectory =
              if pkgs.stdenv.isLinux then lib.mkDefault "/home/${u}"
              else if pkgs.stdenv.isDarwin then lib.mkDefault "/Users/${u}"
              else abort "Unsupported OS";
          };

        })
        # disable version check
        { home.enableNixpkgsReleaseCheck = false; }
      ] ++ (users.${u});
    });
  }
]
