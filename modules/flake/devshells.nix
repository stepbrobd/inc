{
  perSystem = { pkgs, inputs', ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # from local overlay
        colmena

        direnv
        git
        nix-direnv
        nixpkgs-fmt
        sops

        inputs'.terranix.packages.default
        opentofu
      ];
    };
  };
}
