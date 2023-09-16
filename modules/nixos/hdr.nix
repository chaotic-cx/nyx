{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.hdr;
  gamescopeCfg = config.programs.gamescope;

  gamescopeWSI =
    # We can drop this after https://github.com/NixOS/nixpkgs/pull/255293
    pkgs.stdenvNoCC.mkDerivation {
      pname = "VkLayer_FROG_gamescope_wsi";
      inherit (gamescopeCfg.package) version;
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share
        cp -r ${gamescopeCfg.package}/share/vulkan $out/share/vulkan
      '';
    };

  configuration = strength: {
    boot.kernelPackages = strength cfg.kernelPackages;
    programs.steam.gamescopeSession = {
      enable = true; # HDR can't be used with other WM right now...
      args = [ "--hdr-enabled" ];
      env = {
        DXVK_HDR = "1";
        ENABLE_GAMESCOPE_WSI = "1";
      };
    };
    chaotic.mesa-git.extraPackages = [ gamescopeWSI ];
    hardware.opengl.extraPackages = [ gamescopeWSI ];
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
