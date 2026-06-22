# TODO: drop after
# https://nixpkgs-tracker.ocfox.me/?pr=531286

{ lib
, pkgsPrev
, fetchurl
, asar
, widevine-cdm
}:

pkgsPrev.cider-2.overrideAttrs (final: _: {
  version = "4.0.0";

  src = fetchurl {
    url = "https://repo.cider.sh/apt/pool/main/cider-v${final.version}-linux-x64.deb";
    hash = "sha256-Z5B7VQatTEktt4e7aF5EGDTufgwfRHJzCZ1Lia/aIFk=";
  };

  postInstall = ''
    ${lib.getExe asar} extract $out/lib/cider/resources/app.asar ./cider-build

    ${lib.getExe asar} pack ./cider-build $out/lib/cider/resources/app.asar
    rm -rf ./cider-build

    # Install Widevine CDM for DRM support
    ln -sf ${widevine-cdm}/share/google/chrome/WidevineCdm $out/lib/cider/
  '';
})
