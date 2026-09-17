# FIXME:
# alias EOL buildGo125Module for sops
# drop after
# https://github.com/mic92/sops-nix/issues/983
# https://github.com/mic92/sops-nix/pull/984
{ pkgsFinal }: pkgsFinal.buildGoModule
