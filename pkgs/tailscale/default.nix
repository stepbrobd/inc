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
  version = "1.101.166";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "3d52c3f03e96321f1937e778e99461447b9d88dd";
    hash = "sha256-QMVkYfUYgAQXSN3AEUp4ig6MwHrVGXgK/DR+b2Z4ees=";
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
