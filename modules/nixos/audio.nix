{ inputs, ... }:

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alsa-utils
    easyeffects
    pavucontrol
    roomeqwizard
  ];

  boot = {
    # convert hardirq to regular kernel threads scheduler manage
    # should give audio related higher priority
    kernelParams = [ "threadirqs" ];
    # universal audio thunderbolt driver
    # https://github.com/stepbrobd/uad2
    kernelModules = [ "uad2" ];
    extraModulePackages = [
      (inputs.uad2.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        linuxPackages = config.boot.kernelPackages;
      })
    ];
  };

  programs.librepods.enable = true;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;

    # https://wiki.nixos.org/wiki/PipeWire
    extraConfig = {
      pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
          "default.clock.quantum" = 128;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 1024;
        };
      };
      pipewire-pulse."92-low-latency" = {
        "context.properties" = [
          {
            name = "libpipewire-module-protocol-pulse";
            args = { };
          }
        ];
        "pulse.properties" = {
          "pulse.min.req" = "32/48000";
          "pulse.default.req" = "128/48000";
          "pulse.max.req" = "1024/48000";
          "pulse.min.quantum" = "32/48000";
          "pulse.max.quantum" = "1024/48000";
        };
        "stream.properties" = {
          "node.latency" = "128/48000";
          "resample.quality" = 4;
        };
      };
    };
  };
}
