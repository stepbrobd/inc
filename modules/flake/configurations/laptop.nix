{ getSystem, inputs, lib }:

let
  inherit (lib) mkSystem;

  # instead of setting specialArgs.pkgs, set pkgs in a module
  # https://discourse.nixos.org/t/misleading-error-from-specialargs-pkgs-mypkgs/66384/2
  unification = system: { nixpkgs = { inherit ((getSystem system).allModuleArgs) pkgs; }; };
  specialArgs = { inherit inputs lib; };
in
{
  flake.darwinConfigurations = {
    # MacBook Pro 14-inch, Apple M2 Max, 64GB RAM, 1TB Storage
    macbook = mkSystem rec {
      inherit inputs specialArgs;
      os = "darwin";
      platform = "aarch64-darwin";
      entrypoint = ../../../hosts/laptop/macbook;
      users = {
        ysun = with inputs.self; [
          hmModules.ysun.darwin
          hmModules.ysun.trampoline
        ];
      };
      modules = with inputs.self.darwinModules; [
        (unification platform)
        aerospace
        common
        fonts
        # hammerspoon
        homebrew
        # linux-builder # wait and see if https://discourse.nixos.org/t/67617 will get merged into mainline
        nixbuild
        ntpd-rs
        passwordless
        sshd
        system
        tailscale
        trampoline
        inputs.srvos.darwinModules.desktop
      ];
    };
  };

  flake.nixosConfigurations =
    let
      common = with inputs; [
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        generators.nixosModules.all-formats
        hardware.nixosModules.common-hidpi
        self.nixosModules.common
        self.nixosModules.cross
        self.nixosModules.docker
        self.nixosModules.graphical
        self.nixosModules.ip-forwarding
        self.nixosModules.minimal
        self.nixosModules.passwordless
        self.nixosModules.power
        srvos.nixosModules.desktop
      ];
    in
    {
      # Framework Laptop 13, Intel Core i7-1360P, 64GB RAM, 1TB Storage
      framework = mkSystem rec {
        inherit inputs specialArgs;
        os = "nixos";
        platform = "x86_64-linux";
        entrypoint = ../../../hosts/laptop/framework;
        users = { ysun = with inputs.self; [ hmModules.ysun.linux ]; };
        modules = with inputs; common ++ [
          (unification platform)
          hardware.nixosModules.framework-13th-gen-intel
        ];
      };

      # XPS 13 9305, Intel COre i5-1135G7, 16GB RAM, 512GB Storage
      xps = mkSystem rec {
        inherit inputs specialArgs;
        os = "nixos";
        platform = "x86_64-linux";
        entrypoint = ../../../hosts/laptop/xps;
        users = { ysun = with inputs.self; [ hmModules.ysun.linux ]; };
        modules = with inputs; common ++ [
          (unification platform)
          hardware.nixosModules.dell-xps-13-9300
          self.nixosModules.ebpf
        ];
      };
    };
}
