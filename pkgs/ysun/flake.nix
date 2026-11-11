{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  inputs.systems.url = "github:nix-systems/triplet";

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f (import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "ysun";
      }));
    in
    {
      overlays.default = final: _: { ysun = final.callPackage ./default.nix { }; };
      devShells = eachSystem (pkgs: { default = import ./shell.nix { inherit pkgs; }; });
      formatter = eachSystem (pkgs: pkgs.callPackage ./formatter.nix { });
      packages = eachSystem (pkgs: rec {
        default = ysun;
        ysun = pkgs.callPackage ./default.nix { };
      });
    };
}
