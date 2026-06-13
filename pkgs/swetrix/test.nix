{ inputs, pkgs }:

pkgs.testers.nixosTest {
  name = "swetrix";

  nodes.machine = { ... }: {
    imports = [ inputs.self.nixosModules.swetrix ];

    virtualisation.memorySize = 2048;

    services.swetrix = {
      enable = true;
      clickhouse.enable = true;
      redis.enable = true;
      settings = {
        BASE_URL = "http://localhost";
        API_ORIGIN = "http://[::1]:5005";
        SECRET_KEY_BASE = "swetrix-nixos-vm-test-secret-key-base-not-a-real-secret";
        LISTEN_HOST = "::1";
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("clickhouse.service")
    machine.wait_for_unit("redis-swetrix.service")

    machine.wait_until_succeeds("curl -sf 'http://[::1]:8123/ping'", timeout=60)
    machine.wait_until_succeeds("redis-cli -h ::1 -p 6379 ping | grep -q PONG", timeout=30)

    machine.succeed(
        "curl -sf 'http://[::1]:8123/?query="
        "SELECT%20count()%20FROM%20system.users%20WHERE%20name%3D%27swetrix%27' | grep -qx 1"
    )

    machine.wait_for_unit("swetrix-api.service")
    machine.wait_until_succeeds("curl -sf 'http://[::1]:5005/ping'", timeout=90)

    # The API must actually hold a Redis connection over ::1. ioredis retries
    # silently on auth failure, so /ping alone wouldn't catch a broken REDIS_*.
    # Upstream reads process.env.REDIS_PASSWORD directly (no 'password' default),
    # so against our passwordless instance the API must show up in connected_clients
    # (>=2: at least the API's connection plus this redis-cli probe).
    machine.wait_until_succeeds(
        "redis-cli -h ::1 -p 6379 info clients | grep -qE 'connected_clients:([2-9]|[1-9][0-9]+)'",
        timeout=60,
    )

    sockets = machine.succeed("ss -ltnH 'sport = :5005'")
    assert "[::1]:5005" in sockets, f"API not bound to ::1: {sockets!r}"
    assert "0.0.0.0:5005" not in sockets and "[::]:5005" not in sockets, f"API bound publicly: {sockets!r}"

    machine.succeed(
        "curl -sf 'http://[::1]:8123/?query="
        "EXISTS%20TABLE%20analytics.events' | grep -qx 1"
    )

    machine.wait_for_unit("swetrix.service")
    machine.wait_until_succeeds("curl -sf http://127.0.0.1:3000/ping", timeout=60)

    machine.systemctl("restart swetrix-api.service")
    machine.wait_for_unit("swetrix-api.service")
    machine.wait_until_succeeds("curl -sf 'http://[::1]:5005/ping'", timeout=60)
  '';
}
