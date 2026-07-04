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
  version = "1.101.165";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "943b97e2f3fa56c88fae65b9da9134ea6a9ef0bd";
    hash = "sha256-Yyy8WkYeIkf4I+2Vo+RslTVn9yVWhNEO40C3jX5y38I=";
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
