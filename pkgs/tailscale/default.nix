{ lib
, pkgsPrev
, fetchFromGitHub
, writeShellApplication
, nix-prefetch-github
, coreutils
, git
, gnused
, jq
}:

pkgsPrev.tailscale.overrideAttrs (prev: {
  version = "1.101.162";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "be16cc0d3d62193c8541d77befb76def799bf2a8";
    hash = "sha256-Xokno7GNnGPfdb/4ioiaP5/gtupNo7XrODFqp1G32Vo=";
  };

  vendorHash = "sha256-UrvJ5fM+Oqgu2pZwhg5AnUcgi8wPwZ8qDwWpXNmKaPk=";

  passthru = (prev.passthru or { }) // {
    autobump = true;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "tailscale-updater";
        text = lib.readFile ./update.sh;
        runtimeInputs = [
          coreutils
          git
          gnused
          jq
          nix-prefetch-github
        ];
      }))
    ];
  };
})
