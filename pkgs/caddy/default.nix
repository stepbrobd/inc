{ inputs, stdenv }:

# pull caddy from `inputs` directly to prevent infinite recursion
# as `caddy.withPlugins` is implemented with override
inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.caddy.withPlugins {
  hash = "sha256-c/sBu0WLCvHspzbFxh5s0ETDkNPxf5xSAmpLiYi7R6s=";
  plugins = [
    "github.com/andybalholm/brotli@v1.2.6"
    "github.com/caddy-dns/cloudflare@v0.2.4"
    "github.com/relvacode/caddy-oidc@v0.4.3"
    "github.com/stepbrobd/caddy-sigsci@v0.0.0-20261010193943-3aee444999ae"
    "github.com/stepbrobd/certmagic-s3@v0.0.0-20261011090112-d4ee15da1ea9"
    "github.com/ueffel/caddy-brotli@v1.6.0"
  ];
}
