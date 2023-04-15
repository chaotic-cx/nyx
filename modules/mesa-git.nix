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
  };
  config = {
    hardware.opengl = lib.mkIf cfg.mesa-git.enable {
      package = pkgs.mesa_git.drivers;
      package32 = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86) pkgs.mesa_git-32.drivers;
      extraPackages = [ pkgs.mesa_git.opencl ];
    };

    specialisation.stable-mesa = lib.mkIf cfg.mesa-git.enable {
      configuration = {
        system.nixos.tags = [ "stable-mesa" ];
        hardware.opengl.package = lib.mkForce pkgs.mesa.drivers;
        hardware.opengl.package32 = lib.mkForce pkgs.pkgsi686Linux.mesa.drivers;
      };
    };
  };
}
