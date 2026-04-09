{ inputs, lib, getSystem, ... }:

let
  inherit (lib) mkColmena;

  colmena =
    let
      specialArgs = { inherit inputs lib; };

      serverModules = with inputs; [
        disko.nixosModules.disko
        self.nixosModules.acme
        self.nixosModules.as10779
        self.nixosModules.attic
        self.nixosModules.caddy
        self.nixosModules.calibre
        self.nixosModules.common
        self.nixosModules.desktop
        self.nixosModules.glance
        self.nixosModules.golink
        self.nixosModules.grafana
        self.nixosModules.home-assistant
        self.nixosModules.ip-forwarding
        self.nixosModules.jitsi
        self.nixosModules.kanidm
        self.nixosModules.maxmind
        self.nixosModules.minimal
        self.nixosModules.monitoring
        self.nixosModules.neogrok
        self.nixosModules.passwordless
        self.nixosModules.plausible
        self.nixosModules.server
        self.nixosModules.vaultwarden
        self.nixosModules.ysun
        rfm.nixosModules.default
        srvos.nixosModules.common
        srvos.nixosModules.server
      ];

      laptopModules = with inputs; [
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

      darwinModules = with inputs.self.darwinModules; [
        aerospace
        common
        fonts
        # hammerspoon
        homebrew
        # linux-builder
        nixbuild
        ntpd-rs
        passwordless
        sshd
        system
        tailscale
        trampoline
        inputs.srvos.darwinModules.desktop
      ];

      serverUsers = { ysun = with inputs.self; [ hmModules.ysun.minimal ]; };
      laptopUsers = { ysun = with inputs.self; [ hmModules.ysun.linux ]; };
      darwinUsers = {
        ysun = with inputs.self; [
          hmModules.ysun.darwin
          hmModules.ysun.trampoline
        ];
      };
    in
    mkColmena {
      inherit inputs specialArgs getSystem;
      nixpkgs = inputs.nixpkgs;
      nix-darwin = inputs.darwin;
      hosts = [
        {
          os = "nixos";
          platform = "x86_64-linux";
          modules = serverModules;
          users = serverUsers;
          names = [
            "baldy" # NetActuate Los Angeles, 2 vCPU, 8GB RAM, 100GB Storage
            "butte" # Virtua Cloud, 1 vCPU, 2GB RAM, 20GB Storage
            "cradle" # NetActuate Sydney, 2 vCPU, 8GB RAM, 100GB Storage
            "halti" # Garnix.io Hosting, test server
            "highline" # Neptune Networks, 2 vCPU, 2GB RAM, 80GB Storage
            "kongo" # Vultr, 1 vCPU, 2GB RAM, 64GB Storage
            "lagern" # AWS, T3.Large, 25GB Storage
            "lantau" # NetActuate Hong Kong, 2 vCPU, 8GB RAM, 100GB Storage
            "odake" # SSDNodes NRT Performance, 8 vCPU, 32GB RAM, 640GB Storage
            "oxide" # Oxide Computer, 16 vCPU, 128GB RAM, 256GB Storage
            "roraima" # NetActuate Sao Paulo, 2 vCPU, 8GB RAM, 100GB Storage
            "rysy" # NetActuate Warsaw, 2 vCPU, 8GB RAM, 100GB Storage
            "timah" # Misaka Networks, 1 vCPU, 2GB RAM, 32 GB Storage
            "toompea" # V.PS Pro Tallinn, 4 vCPU, 4GB RAM, 40GB Storage
            "walberla" # Hetzner Cloud CX32, 4 vCPU, 8GB RAM, 80GB Storage
          ];
        }
        {
          os = "nixos";
          platform = "aarch64-linux";
          modules = serverModules;
          users = serverUsers;
          names = [
            "isere" # Raspberry Pi 4, 8GB RAM, 500GB Storage
          ];
        }
        {
          os = "nixos";
          platform = "x86_64-linux";
          modules = laptopModules ++ (with inputs; [
            hardware.nixosModules.framework-13th-gen-intel
          ]);
          users = laptopUsers;
          names = [ "framework" ];
        }
        {
          os = "nixos";
          platform = "x86_64-linux";
          modules = laptopModules ++ (with inputs; [
            hardware.nixosModules.dell-xps-13-9300
            self.nixosModules.ebpf
          ]);
          users = laptopUsers;
          names = [ "xps" ];
        }
        {
          os = "darwin";
          platform = "aarch64-darwin";
          modules = darwinModules;
          users = darwinUsers;
          names = [ "macbook" ];
        }
      ];
    };

  colmenaHive = lib.makeHive colmena;

  nixosConfigurations = lib.filterAttrs (_: v: v.class == "nixos") colmenaHive.nodes;
  darwinConfigurations = lib.filterAttrs (_: v: v.class == "darwin") colmenaHive.nodes;
in
{ flake = { inherit colmenaHive nixosConfigurations darwinConfigurations; }; }
