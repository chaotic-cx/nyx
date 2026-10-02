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
  config =
    let
      path = lib.mkDefault (
        lib.lists.optionals registryCfg.enable [
          "chaotic=${if pathCfg.enable then "flake:chaotic" else flakes.self}"
        ]
      );
    in
    {
      nix = lib.mkMerge [
        (
          if lib.versionAtLeast lib.version "26.11pre" then
            { settings.nix-path = path; }
          else
            { nixPath = path; }
        )
        {
          registry = lib.mkIf pathCfg.enable {
            chaotic.flake = flakes.self;
          };
        }
      ];
    };
}
