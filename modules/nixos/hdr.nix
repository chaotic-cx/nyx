{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.hdr;

  gamescopeWSI =
    # We can drop this after https://github.com/NixOS/nixpkgs/pull/255293
    pkgs.stdenvNoCC.mkDerivation {
      pname = "VkLayer_FROG_gamescope_wsi";
      inherit (config.programs.gamescope.package) version;
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share
        cp -r ${config.programs.gamescope.package}/share/vulkan $out/share/vulkan
      '';
    };

  configuration = strength: {
    system.nixos.tags = [ "hdr" ];
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
  #config = lib.mkIf cfg.enable (if cfg.specialisation.enable then {
  #  specialisation.hdr.configuration = configuration lib.mkForce;
  #} else configuration (x: x));
}
