{ flakes }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic;
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
        environment.variables =
          {
            DXVK_HDR = "1";
            ENABLE_GAMESCOPE_WSI = "1";
          };
        programs.steam.gamescopeSession = {
          enable = true; # HDR can't be used with other WM right now...
          args = [ "--hdr-enabled" ];
        };
      };
    };
  };
}
