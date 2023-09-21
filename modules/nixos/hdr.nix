{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.hdr;
  gamescopeCfg = config.programs.gamescope;

  configuration = strength: {
    boot.kernelPackages = strength cfg.kernelPackages;
    programs.steam.gamescopeSession.enable = true; # HDR can only be used with headless Gamescope right now...
    programs.gamescope = {
      args = [ "--hdr-enabled" ];
      env = {
        DXVK_HDR = "1";
        ENABLE_GAMESCOPE_WSI = "1";
      };
    };
    environment.systemPackages = [ gamescopeCfg.package.lib ];
  };

  sysConfig = lib.mkIf (!cfg.specialisation.enable) (configuration (x: x));

  specConfig = lib.mkIf cfg.specialisation.enable {
    specialisation.hdr.configuration = configuration lib.mkForce // {
      system.nixos.tags = [ "hdr" ];
    };
  };
in
{
  options.chaotic.hdr = with lib; {
    enable =
      mkEnableOption ''AMD-HDR as seen in
        https://lore.kernel.org/amd-gfx/20230810160314.48225-1-mwen@igalia.com/
      '';
    specialisation.enable =
      mkOption {
        default = true;
        example = false;
        type = types.bool;
        description = ''
          Isolates the changes in a specialisation.
        '';
      };
    kernelPackages =
      mkOption {
        default = pkgs.linuxPackages_cachyos;
        defaultText = literalExpression "pkgs.linuxPackages_cachyos";
        example = literalExpression "pkgs.linuxKernel.packages.linux_hdr";
        type = types.raw;
        description = ''
          Kernel+packages with "AMD Color Management" patches applied.
        '';
      };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [ sysConfig specConfig ]);
}
