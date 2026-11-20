{ inputs, lib, getSystem, ... }:

let
  inherit (lib) mkColmena;

  colmena =
    let
      specialArgs = { inherit inputs lib; };

      serverModules = with inputs; [
        disko.nixosModules.disko
        self.nixosModules.acme
        self.nixosModules.caddy
        self.nixosModules.ci
        self.nixosModules.common
        self.nixosModules.desktop
        self.nixosModules.glance
        self.nixosModules.go-csp-collector
        self.nixosModules.grafana
        self.nixosModules.home-assistant
        self.nixosModules.jitsi
        self.nixosModules.kanidm
        self.nixosModules.maxmind
        self.nixosModules.minimal
        self.nixosModules.monitoring
        self.nixosModules.neogrok
        self.nixosModules.niks3
        self.nixosModules.nix-community
        self.nixosModules.nixbuild
        self.nixosModules.paperless
        self.nixosModules.passwordless
        self.nixosModules.plausible
        self.nixosModules.routing
        self.nixosModules.server
        self.nixosModules.stump
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
        self.nixosModules.minimal
        self.nixosModules.nix-community
        self.nixosModules.nixbuild
        self.nixosModules.passwordless
        self.nixosModules.power
        srvos.nixosModules.desktop
      ];

      darwinModules = with inputs.self.darwinModules; [
        aerospace
        common
        fonts
        homebrew
        nix-community
        nixbuild
        ntpd-rs
        passwordless
        ranet3
        sshd
        system
        tailscale
        inputs.ranet3.darwinModules.ranet3
        inputs.srvos.darwinModules.desktop
      ];

      serverUsers = { ysun = with inputs.self; [ hmModules.ysun.server ]; };
      laptopUsers = { ysun = with inputs.self; [ hmModules.ysun.linux ]; };
      darwinUsers = { ysun = with inputs.self; [ hmModules.ysun.darwin ]; };
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
            "baldy" # NetActuate, Los Angeles, 2 vCPU, 8GB RAM, 100GB Storage
            "butte" # Virtua Cloud, Paris, 2 vCPU, 2GB RAM, 60GB Storage
            "cradle" # NetActuate, Sydney, 2 vCPU, 8GB RAM, 100GB Storage
            "faber" # Vultr, Singapore, 2 vCPU, 4GB RAM, 80GB Storage
            "feldberg" # Vultr, Frankfurt, 4 vCPU, 8GB RAM, 160GB Storage
            "guadalupe" # Vultr, Dallas, 2 vCPU, 4GB RAM, 80GB Storage
            "highline" # Neptune Networks, New York City, 2 vCPU, 2GB RAM, 80GB Storage
            "kebnekaise" # Vultr, Stockholm, 2 vCPU, 4GB RAM, 80GB Storage
            "kongo" # Vultr, Tokyo, 2 vCPU, 4GB RAM, 80GB Storage
            "lagern" # AWS, Zurich, T3.Large, 25GB Storage
            "lantau" # NetActuate, Hong Kong, 2 vCPU, 8GB RAM, 100GB Storage
            "montmartre" # Vultr, Paris, 4 vCPU, 8GB RAM, 160GB Storage
            "morasko" # POZMAN, Poznań, 2 vCPU, 8GB RAM, 50GB Storage
            "namsan" # Vultr, Seoul, 2 vCPU, 4GB RAM, 80GB Storage
            "noches" # HPE DL380 Gen 10, Grenoble, 2 x Xeon Gold 5218, 128GB RAM, 2 x 512GB SSD RAID1
            "odake" # SSDNodes, Tokyo, Performance, 8 vCPU, 32GB RAM, 640GB Storage
            "roraima" # NetActuate, Sao Paulo, 2 vCPU, 8GB RAM, 100GB Storage
            "rysy" # NetActuate, Warsaw, 2 vCPU, 8GB RAM, 100GB Storage
            "timah" # Misaka Networks, Singapore, 1 vCPU, 2GB RAM, 32 GB Storage
            "toompea" # V.PS, Tallinn, Pro, 4 vCPU, 4GB RAM, 40GB Storage
            "walberla" # Hetzner Cloud, Falkenstein, CX32, 4 vCPU, 8GB RAM, 80GB Storage
            "watchung" # Vultr, Piscataway, 2 vCPU, 4GB RAM, 80GB Storage
          ];
        }
        {
          os = "nixos";
          platform = "aarch64-linux";
          modules = serverModules;
          users = serverUsers;
          names = [
            "isere" # Raspberry Pi 4, Grenoble, 8GB RAM, 500GB Storage
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
            self.nixosModules.caddy
            self.nixosModules.mcp
            hardware.nixosModules.dell-xps-13-9300
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
