{ pkgsPrev, fetchurl }:

pkgsPrev.mas.overrideAttrs (final: _: {
  meta.platforms = [ "aarch64-darwin" ];

  version = "7.0.0-receipt";

  dontPatchShebangs = true;

  src = fetchurl {
    url = "https://github.com/stepbrobd/mas/releases/download/v${final.version}/mas-${final.version}-arm64.pkg";
    hash = "sha256-D/7wYd/U4bzx6i93v9KRQhW//gl9lkBdhnsdayWeNU8=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/local/opt/mas/libexec/bin/mas "$out/libexec/bin/mas"
    install -Dm755 usr/local/opt/mas/bin/mas "$out/bin/mas"

    installManPage usr/local/opt/mas/share/man/man1/mas.1
    installShellCompletion --bash usr/local/opt/mas/etc/bash_completion.d/mas
    installShellCompletion --fish usr/local/opt/mas/share/fish/vendor_completions.d/mas.fish

    runHook postInstall
  '';
})
