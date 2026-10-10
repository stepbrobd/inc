{ inputs, stdenv }:

# pull caddy from `inputs` directly to prevent infinite recursion
# as `caddy.withPlugins` is implemented with override
inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.caddy.withPlugins {
  hash = "sha256-E7anZ2RRcGTy56yxz+1e0/CvKK0Th4NxYSjL1Cyk+s8=";
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.2.4"
    "github.com/relvacode/caddy-oidc@v0.4.3"
    "github.com/stepbrobd/caddy-sigsci@v0.0.0-20261010193943-3aee444999ae"
    "github.com/stepbrobd/certmagic-s3@v0.0.0-20260906102855-4c0666564d10"
    "github.com/ueffel/caddy-brotli@v1.6.0"
  ];
}
