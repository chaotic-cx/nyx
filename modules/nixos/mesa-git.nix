{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.chaotic.mesa-git;

  has32 = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86;

  replaceConfig = {
    system.replaceDependencies.replacements = [
      {
        oldDependency = pkgs.mesa.out;
        newDependency = pkgs.mesa_git.out;
      }
      {
        oldDependency = pkgs.pkgsi686Linux.mesa.out;
        newDependency = pkgs.mesa32_git.out;
      }
    ];
  };

  commonConfig = {
    hardware.graphics = with lib; {
      enable = mkForce true;
      package = mkForce pkgs.mesa_git;
      package32 = mkForce pkgs.mesa32_git;
      extraPackages = mkForce cfg.extraPackages;
      extraPackages32 = mkForce cfg.extraPackages32;
      enable32Bit = mkForce has32;
    };
  };

  specialisationConfig = {
    specialisation.stable-mesa.configuration = {
      system.nixos.tags = [ "stable-mesa" ];
      chaotic.mesa-git.enable = lib.mkForce false;
    };
  };

  assertionConfig = {
    assertions = [
      {
        assertion = lib.versionAtLeast pkgs.mesa.version "24.3.0";
        message = "chaotic.mesa-git no longer supports nixos-24.11, please upgrade to nixos-25.05 or nixos-unstable.";
      }
    ];
  };
in
{
  options = with lib; {
    chaotic.mesa-git = {
      enable = mkOption {
        default = false;
        example = true;
        type = types.bool;
        description = ''
          Whether to use latest Mesa drivers.

          WARNING: It will break NVIDIA's libgbm, don't use with NVIDIA Optimus setups.
        '';
      };

      fallbackSpecialisation = mkOption {
        default = true;
        example = false;
        type = types.bool;
        description = ''
          Whether to add a specialisation with stable Mesa.
          Recommended.
        '';
      };

      replaceBasePackage = mkOption {
        default = false;
        example = false;
        type = types.bool;
        description = ''
          Whether to impurely replace `mesa.out` with `mesa_git.out`.
          Might increase compatibility. But you'll need `--impure` to build your configuration.
        '';
      };

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "with pkgs; [ mesa_git.opencl intel-media-driver intel-ocl vaapiIntel ]";
        description = ''
          Additional packages to add to OpenGL drivers.
          This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          WARNING: Don't use any of the `mesa.*`, replace with `pkgs.mesa_git.*`.
        '';
      };

      extraPackages32 = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "with pkgs.pkgsi686Linux; [ pkgs.mesa32_git.opencl intel-media-driver vaapiIntel ]";
        description = ''
          Additional packages to add to 32-bit OpenGL drivers on 64-bit systems.

          WARNING: Don't use any of the `mesa.*`, replace with `pkgs.mesa32_git.*`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      assertionConfig
      (lib.mkIf cfg.fallbackSpecialisation specialisationConfig)
      commonConfig
      (lib.mkIf cfg.replaceBasePackage replaceConfig)
    ]
  );
}
