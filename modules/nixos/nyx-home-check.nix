{
  config,
  options,
  lib,
  ...
}:
let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.attrsets) optionalAttrs;
in
{
  # Under circumstances where a user is using pkgs from their NixOS
  # configuration,
  config = optionalAttrs (options ? home-manager) {
    home-manager.sharedModules = mkIf config.home-manager.useGlobalPkgs [
      (
        { options, ... }:
        {
          config = optionalAttrs (options ? chaotic.nyx.overlay) {
            # the overlay should not be added to nixpkgs.overlays as this causes a
            # warning which may eventually become an error, but is also
            # generally bad form anyway.
            chaotic.nyx.overlay.enable = mkDefault false;
          };
        }
      )
    ];
  };
}
