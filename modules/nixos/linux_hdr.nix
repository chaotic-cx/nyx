{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic;

  gamescopeWSI =
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
in
{
  options = {
    chaotic.linux_hdr.specialisation.enable =
      lib.mkOption {
        default = false;
        description = ''
          Adds an specialisation for booting with AMD-HDR (re-uses chaotic#linux_cachyos adding extra envvars).
        '';
      };
  };
  config = {
    specialisation.hdr = lib.mkIf cfg.linux_hdr.specialisation.enable {
      configuration = {
        system.nixos.tags = [ "hdr" ];
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
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
    };
  };
}
