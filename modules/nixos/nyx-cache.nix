{ flakes }:
{ config, lib, ... }:
let
  cfg = config.chaotic.nyx.cache;
in
{
  options = with lib; {
    chaotic.nyx.cache.enable = mkOption {
      default = true;
      example = false;
      type = types.bool;
      description = ''
        Whether to add Chaotic-Nyx's binary cache to settings.
      '';
    };
  };
  config = {
    nix.settings =
      lib.mkIf cfg.enable
        # On NixOS (and not Home-Manager, flakes, or shells) we want them without the "extra-" prefix.
        (
          with flakes.self.nixConfig;
          {
            substituters = extra-substituters;
            trusted-public-keys = extra-trusted-public-keys;
          }
        );
  };
}
