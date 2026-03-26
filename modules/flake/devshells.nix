{
  perSystem = { pkgs, inputs', ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # from local overlay
        colmena
        stepbrobd

        direnv
        git
        nix-direnv
        sops

        inputs'.terranix.packages.default
        (opentofu.withPlugins (p: with p; [ cloudflare_cloudflare carlpett_sops tailscale_tailscale ]))
      ];
    };
  };
}
