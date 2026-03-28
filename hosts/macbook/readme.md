# MacBook Pro 14-inch

Flake attribute: `macbook`

CPU: Apple M2 Max

RAM: 64GB

Storage: 1TB

Troubleshooting:

- if `/nix` is not mounting on boot:
  [nix-installer#1261](https://github.com/determinatesystems/nix-installer/issues/1261)

## Preparation

> [!Important] Ensure the Security Policy for the boot partition is set to "Full
> Security" in the
> [recovery menu](https://support.apple.com/guide/security/startup-disk-security-policy-control-sec7d92dc49f/web).

Follow macOS built-in setup tool.

Once inside the operating system, install Xcode Command Line Tools:

```shell
xcode-select --install
```

Install [Homebrew](https://brew.sh).

Sign-in to App Store (required for `nix-darwin.options.homebrew.masApps`).

## Installation

Install `nix` with
[Determinate Systems Nix Installer](https://github.com/determinatesystems/nix-installer).

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
```

Remove generated `nix` configuration:

```shell
sudo rm /etc/nix/nix.conf
```

Start a new terminal to activate `nix`.

Activate the system:

```shell
nix --extra-experimental-features "nix-command flakes" run github:lnl7/nix-darwin -- switch --flake github:stepbrobd/dotfiles#macbook
```

That's it!
