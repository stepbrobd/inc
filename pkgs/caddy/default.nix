{ inputs, stdenv }:

# pull caddy from `inputs` directly to prevent infinite recursion
# as `caddy.withPlugins` is implemented with override
inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.caddy.withPlugins {
  hash = "sha256-hsAE//hh+tn4JNQ4Nqp1/n5/l5XndzOGU48cB0/Ow9Q=";
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.2.4"
    "github.com/molecule-man/go-brrr@v1.3.1"
    "github.com/relvacode/caddy-oidc@v0.4.3"
    "github.com/stepbrobd/caddy-sigsci@v0.0.0-20261107032002-4166b0fc6fb7"
    "github.com/stepbrobd/certmagic-s3@v0.0.0-20261011090112-d4ee15da1ea9"
    "github.com/ueffel/caddy-brotli@v1.7.0"
  ];
}
