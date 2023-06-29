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
          Adds an specialisation for booting with linux_hdr.
        '';
      };
  };
  config = {
    specialisation.hdr = lib.mkIf cfg.linux_hdr.specialisation.enable {
      configuration = {
        system.nixos.tags = [ "hdr" ];
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_hdr;
        environment.variables =
          {
            DXVK_HDR = "1";
            ENABLE_GAMESCOPE_WSI = "1";
          };
        chaotic.gamescope.session.args = [ "--hdr-enabled" ];
      };
    };
  };
}
