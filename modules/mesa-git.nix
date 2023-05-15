{ inputs }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic.mesa-git;

  package = pkgs.buildEnv {
    name = "opengl-drivers";
    paths = [
      pkgs.mesa_git.out
      pkgs.mesa_git.drivers
    ] ++ cfg.extraPackages;
  };

  package32 = pkgs.buildEnv {
    name = "opengl-drivers-32bit";
    paths = [
      pkgs.mesa32_git.out
      pkgs.mesa32_git.drivers
    ] ++ cfg.extraPackages32;
  };

  has32 = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86;
in
{
  options = {
    chaotic.mesa-git = {
      enable = lib.mkOption {
        default = false;
        description = ''
          Whether to use latest Mesa drivers.

          WARNING: It will break NVIDIA's libgbm, don't use with NVIDIA Optimus setups.
        '';
      };

      extraPackages = with lib; mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExpression "with pkgs; [ mesa_git.opencl intel-media-driver intel-ocl vaapiIntel ]";
        description = mdDoc ''
          Additional packages to add to OpenGL drivers.
          This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          WARNING: Don't use any of the `mesa.*`, replace with `pkgs.mesa_git.*`.
        '';
      };

      extraPackages32 = with lib; mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExpression "with pkgs.pkgsi686Linux; [ pkgs.mesa32_git.opencl intel-media-driver vaapiIntel ]";
        description = mdDoc ''
          Additional packages to add to 32-bit OpenGL drivers on 64-bit systems.

          WARNING: Don't use any of the `mesa.*`, replace with `pkgs.mesa32_git.*`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    specialisation.stable-mesa.configuration = {
      system.nixos.tags = [ "stable-mesa" ];
      chaotic.mesa-git.enable = lib.mkForce false;
    };

    hardware.opengl = with lib; {
      enable = mkForce false;
      package = mkForce pkgs.mesa_git.out;
      package32 = mkForce pkgs.mesa32_git.out;
      extraPackages = mkForce [];
      extraPackages32 = mkForce [];
      driSupport = mkForce true;
      driSupport32Bit = mkForce has32;
      setLdLibraryPath = mkForce false;
    };

    systemd.tmpfiles.rules = [
      "L+ /run/opengl-driver - - - - ${package}"
      (
        if pkgs.stdenv.isi686 then
          "L+ /run/opengl-driver-32 - - - - opengl-driver"
        else if has32 then
          "L+ /run/opengl-driver-32 - - - - ${package32}"
        else
          "r /run/opengl-driver-32"
      )
    ];
    environment.sessionVariables.LD_LIBRARY_PATH =
      ([ "/run/opengl-driver/lib" ] ++ lib.optional has32 "/run/opengl-driver-32/lib");
  };
}
