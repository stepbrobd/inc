# Framework Laptop 13

Flake attribute: `framework`

CPU: Intel Core i7-1360P

RAM: 64GB

Storage: 1TB

## Installation

> [!Important] Disable Secure Boot before getting started.

Boot into minimal NixOS installer and switch to root user.

Format disks:

```shell
bash $(nix --extra-experimental-features "nix-command flakes" --accept-flake-config build --no-link --print-out-paths github:stepbrobd/dotfiles#nixosConfigurations.framework.config.system.build.diskoScript)
```

Install:

```shell
nixos-install --no-root-password --flake github:stepbrobd/dotfiles#framework --option extra-substituters https://cache.garnix.io
```

It's expected to have errors related to
[Lanzaboote](https://github.com/nix-community/lanzaboote) since secure boot PKI
bundle is not setup.

After `nixos-install`, DO NOT reboot.

Create secure boot keys and copy them to new system:

```shell
sbctl create-keys && mv /etc/secureboot /mnt/etc
```

Run installation again:

```shell
nixos-install --no-root-password --flake github:stepbrobd/dotfiles#framework --option extra-substituters https://cache.garnix.io
```

Lanzaboote should not complain this time.

Reboot into NixOS, verify secure boot with:

```shell
sbctl verify
```

It is expected that the files ending with `*-bzImage.efi` are not signed.

Restart the system, `F2` to go to boot menu.

- Administer Secure Boot > Enforce Secure Boot > Enabled

- Administer Secure Boot > Erase all Secure Boot Settings > Enabled

`F10` to save and reboot.

After logging into NixOS, enroll keys:

```shell
sbctl enroll-keys --microsoft
```

Reboot to check secure boot status:

```shell
bootctl status
```

That's it!

## Optional TPM2 Disk Unlock

See more [here](https://jnsgr.uk/2024/04/nixos-secure-boot-tpm-fde/):

```shell
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 /dev/nvme0n1p2
```

## Standalone Disko Setup

Usually not used, managed directly by this flake.

```shell
nix run github:nix-community/disko -- --mode disko ./disko.nix
```

See
[Disko Quick Start Guide](https://github.com/nix-community/disko/blob/master/docs/quickstart.md)
for details.
