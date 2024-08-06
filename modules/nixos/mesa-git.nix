{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.mesa-git;

  has32 = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86;

  methodReplace = {
    hardware.graphics = with lib; {
      enable = mkForce true;
      package = mkForce pkgs.mesa_git.drivers;
      package32 = mkForce pkgs.mesa32_git.drivers;
      extraPackages = mkForce cfg.extraPackages;
      extraPackages32 = mkForce cfg.extraPackages32;
      enable32Bit = mkForce has32;
    };

    system.replaceRuntimeDependencies = [
      { original = pkgs.mesa.out; replacement = pkgs.mesa_git.out; }
      { original = pkgs.pkgsi686Linux.mesa.out; replacement = pkgs.mesa32_git.out; }
    ];
  };

  methodBackend =
    let
      variables = {
        GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm"; # superfluous
        GBM_BACKEND = pkgs.mesa_git.gbmBackend;
      };
    in
    {
      hardware.graphics = with lib; {
        enable = mkForce true;
        package = mkForce pkgs.mesa_git.drivers;
        package32 = mkForce pkgs.mesa32_git.drivers;
        extraPackages = mkForce cfg.extraPackages;
        extraPackages32 = mkForce cfg.extraPackages32;
        enable32Bit = mkForce has32;
      };

      systemd.services.display-manager.environment = variables // {
        LD_PRELOAD = "${pkgs.mesa_git.drivers}/lib/libglapi.so.0"; # Required for SDDM
      };

      environment.sessionVariables = variables // {
        LD_PRELOAD = [ "${pkgs.mesa_git.drivers}/lib/libglapi.so.0" ]; # Required for browser's gltest
      };
    };

  common = {
    specialisation.stable-mesa.configuration = {
      system.nixos.tags = [ "stable-mesa" ];
      chaotic.mesa-git.enable = lib.mkForce false;
    };
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

      method =
        mkOption {
          type = types.enum [
            "replaceRuntimeDependencies"
            "GBM_BACKENDS_PATH"
          ];
          default = "GBM_BACKENDS_PATH";
          example = "replaceRuntimeDependencies";
          description = ''
            There are three available methods to replace your video drivers system-wide:

            - GBM_BACKENDS_PATH:
              The default one that tricks any package linked against nixpkgs' libgbm to
              load our newer one;
            - replaceRuntimeDependencies:
              The second most recommended, which impurely replaces nixpkgs' libgbm with
              ours in the nix store (requires "--impure");
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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.fallbackSpecialisation common)
    (lib.mkIf (cfg.method == "replaceRuntimeDependencies") methodReplace)
    (lib.mkIf (cfg.method == "GBM_BACKENDS_PATH") methodBackend)
  ]);
}
