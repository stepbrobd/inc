{ getSystem, inputs, lib }:

let
  inherit (lib) mkColmena;

  colmena =
    let
      os = "nixos";
      specialArgs = { inherit inputs lib; };

      users = { ysun = with inputs.self; [ hmModules.ysun.minimal ]; };

      modules = with inputs; [
        disko.nixosModules.disko
        self.nixosModules.acme
        self.nixosModules.ysun
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
        self.nixosModules.neogrok
        self.nixosModules.passwordless
        self.nixosModules.plausible
        self.nixosModules.prometheus
        self.nixosModules.server
        self.nixosModules.tsnsrv
        self.nixosModules.vaultwarden
        rfm.nixosModules.default
        srvos.nixosModules.common
        srvos.nixosModules.server
      ];
    in
    (mkColmena rec {
      inherit os inputs specialArgs modules users;
      platform = "x86_64-linux";
      nixpkgs = (getSystem platform).allModuleArgs.pkgs;
      hosts = [
        "butte" # Virtua Cloud, 1 vCPU, 2GB RAM, 20GB Storage
        "halti" # Garnix.io Hosting, test server
        "highline" # Neptune Networks, 2 vCPU, 2GB RAM, 80GB Storage
        "kongo" # Vultr, 1 vCPU, 2GB RAM, 64GB Storage
        "lagern" # AWS, T3.Large, 25GB Storage
        "odake" # SSDNodes NRT Performance, 8 vCPU, 32GB RAM, 640GB Storage
        "timah" # Misaka Networks, 1 vCPU, 2GB RAM, 32 GB Storage
        "toompea" # V.PS Pro Tallinn, 4 vCPU, 4GB RAM, 40GB Storage
        "walberla" # Hetzner Cloud CX32, 4 vCPU, 8GB RAM, 80GB Storage
      ];
    }) // (mkColmena rec {
      inherit os inputs specialArgs modules users;
      platform = "aarch64-linux";
      nixpkgs = (getSystem platform).allModuleArgs.pkgs;
      hosts = [
        "isere" # Raspberry Pi 4, 8GB RAM, 500GB Storage
      ];
    });

  colmenaHive = lib.makeHive colmena;

  nixosConfigurations = colmenaHive.nodes;
in
{ flake = { inherit colmenaHive nixosConfigurations; }; }
