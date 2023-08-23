{ config, lib, ... }:
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
    nix.settings = lib.mkIf cfg.enable {
      substituters = [ "https://nyx.chaotic.cx" ];
      trusted-public-keys = [
        "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];
    };
  };
}
