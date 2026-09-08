{ pkgsPrev, terraform-providers-bin, terraform-provider-arin }:

pkgsPrev.opentofu.withPlugins (_: (with terraform-providers-bin.providers; [
  carlpett.sops
  cloudflare.cloudflare
  fastly.fastly
  hashicorp.aws
  tailscale.tailscale
]) ++ [
  terraform-provider-arin
])
