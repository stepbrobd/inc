{ lib, pkgs, config, ... }:

let
  inherit (lib.blueprint.services.ntpd-rs) domain;
in
{
  systemd.services."serial-getty@ttyAMA0".enable = false;

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyAMA0", OWNER="root", GROUP="gpsd", MODE="0666"
    SUBSYSTEM=="pps", KERNEL=="pps0", OWNER="root", GROUP="gpsd", MODE="0666"
  '';

  srvos.boot.consoles = lib.mkForce [ ];
  boot.kernelParams = [ "nohz=off" ];
  boot.kernelModules = [ "pps-gpio" "pps-ldisc" ];
  hardware.raspberry-pi.config.all = {
    options.force_turbo = {
      enable = true;
      value = 1;
    };

    base-dt-params = {
      uart0 = {
        enable = true;
        value = "on";
      };
      i2c_arm = {
        enable = true;
        value = "on";
      };
      rtc = {
        enable = true;
        value = "off";
      };
    };

    dt-overlays = {
      uart0-pi5 = {
        enable = true;
        params = { };
      };
      i2c-rtc = {
        enable = true;
        params = {
          rv3028.enable = true;
          addr = {
            enable = true;
            value = "0x52";
          };
        };
      };
      pps-gpio = {
        enable = true;
        params.gpiopin = {
          enable = true;
          value = 18;
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ i2c-tools gpsd pps-tools ];

  services.gpsd = {
    enable = true;
    nowait = true;
    readonly = false;
    devices = [ "/dev/ttyAMA0" "/dev/pps0" ];
    extraArgs = [
      "-r"
      "-s"
      "115200"
    ];
  };

  services.ntpd-rs.server = {
    enable = true;
    inherit domain;
  };

  # bind NTP and NTS-KE to addresses in my own block so reply packets have the correct
  # source (dummy0 address) rather than the tailscale0 address the kernel
  # would otherwise select for the outgoing interface
  # e.g.
  # In  IP 100.100.20.2.35421 > 23.161.104.133.123  <- correct dst
  # Out IP 100.100.20.1.123   > 100.100.20.2.35421  <- src should be 23.161.104.133, not 100.100.20.1
  # other non exit servers dont seem to be affected as their requests are termintated with caddy
  # and caddy subsequantly generates traffic internal to kernel
  # so the src address of the proxy backend's reply doesnt matter to the original client
  services.ntpd-rs.settings =
    let
      serverConfig = config.services.ntpd-rs.server;
      ipam = lib.blueprint.hosts.isere.ipam;
    in
    {
      server = lib.mkForce [
        { listen = "${ipam.ipv4}:123"; accept-ntp-versions = serverConfig.acceptedVersions; }
        { listen = "[${ipam.ipv6}]:123"; accept-ntp-versions = serverConfig.acceptedVersions; }
      ];

      # nts experiment pool
      # https://experimental.ntspooltest.org/join
      # https://docs.ntpd-rs.pendulum-project.org/guide/nts-pool/
      nts-ke-server = lib.mkForce [
        {
          listen = "${ipam.ipv4}:4460";
          accept-ntp-versions = serverConfig.acceptedVersions;
          private-key-path = serverConfig.cert.key;
          certificate-chain-path = serverConfig.cert.fullchain;
          # i consider non sensitive
          accepted-pool-authentication-tokens = [ "5ea84788c444c03a83c69e27fcf57074dc9adb5244e7ed4467f9207153260ab2" ];
        }
        {
          listen = "[${ipam.ipv6}]:4460";
          accept-ntp-versions = serverConfig.acceptedVersions;
          private-key-path = serverConfig.cert.key;
          certificate-chain-path = serverConfig.cert.fullchain;
          # i consider non sensitive
          accepted-pool-authentication-tokens = [ "5ea84788c444c03a83c69e27fcf57074dc9adb5244e7ed4467f9207153260ab2" ];
        }
      ];

      source = [
        {
          mode = "sock";
          path = "/run/ntpd-rs/chrony.ttyAMA0.sock";
          precision = 0.005;
        }
        {
          mode = "pps";
          path = "/dev/pps0";
          precision = 0.0000001;
        }
      ];
    };

  # https://docs.ntpd-rs.pendulum-project.org/guide/gps-pps/
  systemd.services.gpsd-socket-shim = {
    description = "gpsd socket shim for ntpd-rs";
    documentation = [ "https://github.com/pendulum-project/ntpd-rs" ];

    after = [ "ntpd-rs.service" ];
    before = [ "gpsd.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'ln -sf /run/ntpd-rs/chrony.ttyAMA0.sock /run/chrony.ttyAMA0.sock'";
      ExecStop = "${pkgs.coreutils}/bin/rm -f /run/chrony.ttyAMA0.sock";
    };
  };

  systemd.services.gpsd = {
    after = [ "gpsd-socket-shim.service" ];
    wants = [ "gpsd-socket-shim.service" ];
  };

  # embed the public grafana dashboard
  services.caddy = {
    enable = true;
    virtualHosts.${domain} = {
      extraConfig = ''
        import common
        header Content-Type "text/html; charset=utf-8"
        respond `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#111217"><title>${domain}</title><style>*{margin:0;padding:0}html,body{background:#111217}html,body,iframe{width:100%;height:100%;border:none;overflow:hidden}</style><script defer data-domain="${domain}" src="https://${lib.blueprint.services.plausible.domain}/js/script.file-downloads.hash.outbound-links.js"></script></head><body><iframe src="https://${lib.blueprint.services.grafana.domain}/public-dashboards/ab5eeb9da69842ebaaf75819d8a62b15"></iframe></body></html>` 200
      '';
    };
  };
}
