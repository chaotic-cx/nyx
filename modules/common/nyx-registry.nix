{ flakes }:
{ config, lib, ... }:
let
  registryCfg = config.chaotic.nyx.registry;
  pathCfg = config.chaotic.nyx.nixPath;
in
{
  options = with lib; {
    chaotic.nyx = {
      registry.enable = mkOption {
        default = true;
        example = false;
        type = types.bool;
        description = ''
          Whether to add Chaotic-Nyx to `nix.registry`.
        '';
      };
      nixPath.enable = mkOption {
        default = true;
        example = false;
        type = types.bool;
        description = ''
          Whether to add Chaotic-Nyx to `nix.settings.nix-path`.
        '';
      };
    };
  };
  config = {
    nix.nixPath = lib.mkDefault (
      lib.lists.optionals pathCfg.enable [
        "chaotic=${if registryCfg.enable then "flake:chaotic" else flakes.self}"
      ]
    );
    nix.registry = lib.mkIf registryCfg.enable {
      chaotic.flake = flakes.self;
    };
  };
}
