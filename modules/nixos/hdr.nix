{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.hdr;

  configuration = strength: {
    programs.steam.gamescopeSession.enable = true; # HDR can only be used with headless Gamescope right now...
    programs.gamescope = {
      args = [ "--hdr-enabled" ];
      env = {
        DXVK_HDR = "1";
        ENABLE_GAMESCOPE_WSI = "1";
      };
    };
    environment.systemPackages = [ cfg.wsiPackage ];
  };

  sysConfig = lib.mkIf (!cfg.specialisation.enable) (configuration (x: x));

  specConfig = lib.mkIf cfg.specialisation.enable {
    specialisation.hdr.configuration = configuration lib.mkForce // {
      system.nixos.tags = [ "hdr" ];
    };
  };
in
{
  options.chaotic.hdr = {
    enable =
      lib.mkEnableOption ''AMD-HDR as seen in
        https://lore.kernel.org/amd-gfx/20230810160314.48225-1-mwen@igalia.com/
      '';
    specialisation.enable =
      lib.mkOption {
        default = true;
        example = false;
        type = lib.types.bool;
        description = ''
          Isolates the changes in a specialisation.
        '';
      };
    wsiPackage =
      lib.mkOption {
        default = pkgs.gamescope-wsi;
        defaultText = lib.literalExpression "pkgs.gamescope-wsi";
        example = lib.literalExpression "pkgs.gamescope-wsi_git";
        type = lib.types.package;
        description = ''
          Gamescope WSI package to use
        '';
      };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [ sysConfig specConfig ]);

  imports = [
    (lib.mkRemovedOptionModule
      [ "chaotic" "hdr" "kernelPackages" ]
      "kernelPackages option is deprecated. Please use a kernel built with the `AMD_PRIVATE_COLOR` flag."
    )
  ];
}
