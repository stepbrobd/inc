{ pkgsPrev, terraform-providers-bin }:

(pkgsPrev.opentofu.withPlugins (_: with terraform-providers-bin.providers; [
  Backblaze.b2
  carlpett.sops
  cloudflare.cloudflare
  fastly.fastly
  tailscale.tailscale
]))
