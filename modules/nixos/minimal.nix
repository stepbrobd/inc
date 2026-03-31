{ inputs, lib, ... }:

{ pkgs, ... }:

{
  # lower  than option default (1500)
  # higher than        default (1000)
  # need to do this since nixos for raspberry pi module set mkDefault
  # for the kernel with rpi firmware, and we'd want to keep that but override
  # the default for other linux machines, which is set by mkOptionDefault
  boot.kernelPackages = lib.mkOverride 1250 pkgs.linuxPackages_latest;

  imports = with inputs.self.nixosModules; [
    fail2ban
    nftables
    ranet
    tailscale
    time
    vxlan
  ];

  services.bpftune.enable = true;

  # services.prometheus.enable = true;

  boot.tmp.cleanOnBoot = true;

  users.mutableUsers = false;

  environment.etc."ssh/ca.pub".text = lib.blueprint.ssh.ca;
  services.openssh = {
    enable = true;
    hostKeys = lib.mkForce [{ type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }];
    extraConfig = ''
      TrustedUserCAKeys /etc/ssh/ca.pub
    '';
    # mostly pq but have fallback for legacy clients
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = lib.mkForce false;
      LoginGraceTime = 30;
      MaxAuthTries = 5;
      MaxStartups = "10:30:60";
      PerSourceMaxStartups = 1;
      AllowAgentForwarding = false;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 5;
      KexAlgorithms = lib.mkForce [
        "mlkem768x25519-sha256"
        "sntrup761x25519-sha512"
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256" # fallback
      ];
      Ciphers = lib.mkForce [
        "chacha20-poly1305@openssh.com"
        "aes256-ctr" # fallback
      ];
      Macs = lib.mkForce [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "hmac-sha2-512" # fallback
      ];
    };
  };

  systemd.services.network-local-commands = {
    before = lib.mkForce [ ];
    after = lib.mkForce [ "network-online.target" "systemd-networkd.service" ];
    wants = lib.mkForce [ "network-online.target" ];
    wantedBy = lib.mkForce [ "multi-user.target" ];
  };

  boot.kernelPatches = lib.singleton {
    name = "kconfig-optimizations";
    patch = null;
    structuredExtraConfig = lib.genAttrs [
      # https://github.com/iovisor/bcc/blob/master/docs/kernel_config.md
      "BPF"
      "BPF_JIT"
      "BPF_JIT_ALWAYS_ON"
      # https://docs.kernel.org/admin-guide/mm/multigen_lru.html
      "LRU_GEN"
      "LRU_GEN_ENABLED"
    ]
      (_: lib.mkForce lib.kernel.yes);
  };

  # network optimizations
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    # bbr congestion control with fq qdisc for pacing
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    # tcp fast open for both client and server
    "net.ipv4.tcp_fastopen" = 3;
    # path mtu discovery (important for vps with non-standard mtu)
    "net.ipv4.tcp_mtu_probing" = 1;
    # keep connections performant after idle
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    # reuse time_wait sockets for outbound connections
    "net.ipv4.tcp_tw_reuse" = 1;
    # listen backlog for busy servers (caddy, bird, etc.)
    "net.core.somaxconn" = 4096;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    # raise buffer ceiling so bpftune has room to auto-tune
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    # tcp auto-tuning range: min default max
    "net.ipv4.tcp_rmem" = "4096 131072 16777216";
    "net.ipv4.tcp_wmem" = "4096 16384 16777216";
    # udp buffer minimums for wireguard/tailscale
    "net.ipv4.udp_rmem_min" = 8192;
    "net.ipv4.udp_wmem_min" = 8192;
    "net.ipv6.udp_rmem_min" = 8192;
    "net.ipv6.udp_wmem_min" = 8192;
    # nic backlog for handling packet bursts
    "net.core.netdev_max_backlog" = 16384;
  };
}
