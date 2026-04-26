{ inputs, stdenv }:

# pull caddy from `inputs` directly to prevent infinite recursion
# as `caddy.withPlugins` is implemented with override
inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.caddy.withPlugins {
  hash = "sha256-wLWFKd3VO/KP/n68fCpBC+fcCZIRcWHkwTTdxNCU2P0=";
  plugins = [
    "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
    "github.com/caddy-dns/cloudflare@v0.2.4"
    "github.com/relvacode/caddy-oidc@v0.3.1"
    "github.com/ss098/certmagic-s3@v0.0.0-20250922022452-8af482af5f39"
    "github.com/ueffel/caddy-brotli@v1.6.0"
  ];
}
