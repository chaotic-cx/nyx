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
    nix.settings = lib.mkIf cfg.enable {
      inherit (flakes.self.nixConfig)
        extra-substituters
        extra-trusted-public-keys
        ;
    };
  };
}
