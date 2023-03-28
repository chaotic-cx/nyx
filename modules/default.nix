{ inputs }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic;
in
{
  options = {
    chaotic.mesa-git.enable =
      lib.mkOption {
        default = false;
        internal = true;
        description = ''
          Whether to use latest Mesa drivers.
        '';
      };
    chaotic.linux_hdr.specialisation.enable =
      lib.mkOption {
        default = false;
        internal = true;
        description = ''
          Adds an specialisation for booting with linux_hdr.
        '';
      };
  };
  config = {
    nixpkgs.overlays = [ inputs.self.overlays.default ];

    hardware.opengl = lib.mkIf cfg.mesa-git.enable {
      package = pkgs.mesa-git.drivers;
      package32 = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86) pkgs.mesa-git-32.drivers;
      extraPackages = [ pkgs.mesa-git.opencl ];
    };

    specialisation.stable-mesa = lib.mkIf cfg.mesa-git.enable {
      configuration = {
        system.nixos.tags = [ "stable-mesa" ];
        hardware.opengl.package = lib.mkForce pkgs.mesa.drivers;
        hardware.opengl.package32 = lib.mkForce pkgs.pkgsi686Linux.mesa.drivers;
      };
    };

    specialisation.hdr = lib.mkIf cfg.linux_hdr.specialisation.enable {
      configuration = {
        system.nixos.tags = [ "hdr" ];
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_hdr;
        environment.variables =
          {
            DXVK_HDR = "1";
            ENABLE_GAMESCOPE_WSI = "1";
          };
        # TODO: programs.gamescope.args = lib.mkForce [ "--rt" "--hdr-enabled" ];
      };
    };
  };
}
