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
    nix.settings = lib.mkIf cfg.enable
      rec {
        # For Non-NixOS
        inherit (flakes.self._dev.nixConfig)
          extra-substituters
          extra-trusted-public-keys;
        # For NixOS
        substituters = extra-substituters;
        trusted-public-keys = extra-trusted-public-keys;
      };
  };
}
