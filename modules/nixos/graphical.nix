{ inputs, lib, ... }:

{ config, options, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
in
{
  imports = with inputs.self.nixosModules; [
    audio
    desktop
    fonts
    i18n
  ];

  config = lib.mkIf (hasTag "graphical") {
    services.desktopManager.enabled =
      lib.mkDefault
        (lib.filter
          hasTag
          options.services.desktopManager.enabled.type.nestedTypes.elemType.functor.payload.values);
  };
}
