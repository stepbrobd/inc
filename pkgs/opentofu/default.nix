{ pkgsPrev, terraform-providers-bin }:

(pkgsPrev.opentofu.withPlugins (_: with terraform-providers-bin.providers; [
  carlpett.sops
  cloudflare.cloudflare
  tailscale.tailscale
]))
