{ pkgsPrev, lib }:

(pkgsPrev.callPackage ./override.nix { }).overrideAttrs {
  prePatch = ''
    substituteInPlace lib/plausible_web/templates/layout/app.html.heex \
      --replace-fail '</head>' '<script defer data-domain="${lib.blueprint.services.plausible.domain}" src="/js/script.file-downloads.hash.outbound-links.js"></script></head>'
  '';
}
