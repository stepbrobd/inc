{ inputs, lib, ... }:

{ pkgs, ... }:

let
  inherit (lib.blueprint.services.vaultwarden) domain;
  bitwarden = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
  amo = slug: {
    installation_mode = "normal_installed";
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  };
in
{
  home.packages = [
    (pkgs.wrapFirefox # policies must be in the unwrapped zen
      (inputs.zen.packages.${pkgs.stdenv.hostPlatform.system}.twilight-unwrapped.override {
        policies = {
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;

          NoDefaultBookmarks = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
          };

          DNSOverHTTPS.Enabled = false;

          PasswordManagerEnabled = false;
          OfferToSaveLogins = false;
          DisableMasterPasswordCreation = true;
          AutofillCreditCardEnabled = false;
          AutofillAddressEnabled = false;

          ExtensionSettings = {
            ${bitwarden} = amo "bitwarden-password-manager" // { default_area = "navbar"; };
            "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = amo "vimium-ff"; # Vimium
            "adguardadblocker@adguard.com" = amo "adguard-adblocker";
            "addon@darkreader.org" = amo "darkreader";
          };
          "3rdparty".Extensions.${bitwarden}.environment.base = "https://${domain}";

          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";

          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
          };

          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
          };
        };
      })
      { })
  ];

  home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isLinux { BROWSER = "zen-twilight"; };

  xdg.mimeApps.enable = pkgs.stdenv.isLinux;
  xdg.mimeApps.defaultApplications = lib.optionalAttrs pkgs.stdenv.isLinux (
    lib.genAttrs [
      "text/html"
      "text/xml"
      "application/xml"
      "application/json"
      "application/xhtml+xml"
      "application/x-extension-htm"
      "application/x-extension-html"
      "application/x-extension-shtml"
      "application/x-extension-xht"
      "application/x-extension-xhtml"
      "application/pdf"
      "application/x-pdf"
      "image/svg+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ]
      (_: [ "zen-twilight.desktop" ])
  );
}
