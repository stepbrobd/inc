{
  services.fail2ban = {
    enable = true;

    bantime = "24h";
    bantime-increment = {
      enable = true;
      overalljails = true;
      maxtime = "720h"; # 30 * 24h
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
    };

    maxretry = 1;

    ignoreIP = [
      "127.0.0.0/8"
      "::1/128"
      # Tailscale
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
  };
}
