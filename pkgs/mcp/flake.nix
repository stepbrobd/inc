{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  inputs.systems.url = "github:nix-systems/triplet";

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _: { mcp = final.callPackage ./default.nix { }; };
      devShells = eachSystem (pkgs: { default = import ./shell.nix { inherit pkgs; }; });
      formatter = eachSystem (pkgs: pkgs.callPackage ./formatter.nix { });
      packages = eachSystem (pkgs: rec {
        default = mcp;
        mcp = pkgs.callPackage ./default.nix { };
      });
    };
}
