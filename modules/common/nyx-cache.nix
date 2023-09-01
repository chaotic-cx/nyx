{ flakes }: { config, lib, ... }:
let
  cfg = config.chaotic.nyx.cache;
in
{
  options = {
    chaotic.nyx.cache.enable =
      lib.mkOption {
        default = true;
        description = ''
          Whether to add Chaotic-Nyx's binary cache to settings.
        '';
      };
  };
  config = {
    nix.settings = lib.mkIf cfg.enable flakes.self._debug.nixConfig;
  };
}
