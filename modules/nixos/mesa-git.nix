{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.mesa-git;

  has32 = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86;

  methodReplace = {
    hardware.opengl = with lib; {
      enable = mkForce true;
      package = mkForce pkgs.mesa_git.drivers;
      package32 = mkForce pkgs.mesa32_git.drivers;
      extraPackages = mkForce cfg.extraPackages;
      extraPackages32 = mkForce cfg.extraPackages32;
      driSupport = mkForce true;
      driSupport32Bit = mkForce has32;
      setLdLibraryPath = mkForce false;
    };

    system.replaceRuntimeDependencies = [
      { original = pkgs.mesa.out; replacement = pkgs.mesa_git.out; }
      { original = pkgs.pkgsi686Linux.mesa.out; replacement = pkgs.mesa32_git.out; }
    ];
  };

  methodBackend =
  let
    variables = {
      GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
      GBM_BACKEND = pkgs.mesa_git.gbmBackend;
    };
  in {
    hardware.opengl = with lib; {
      enable = mkForce true;
      package = mkForce pkgs.mesa_git.drivers;
      package32 = mkForce pkgs.mesa32_git.drivers;
      extraPackages = mkForce (cfg.extraPackages ++ [ pkgs.mesa_git.gbm ]);
      extraPackages32 = mkForce cfg.extraPackages32;
      driSupport = mkForce true;
      driSupport32Bit = mkForce has32;
      setLdLibraryPath = mkForce false;
    };

    systemd.services.display-manager.environment = variables;

    environment.sessionVariables = variables // {
      LD_PRELOAD = [ "${pkgs.mesa_git}/lib/libglapi.so.0" ]; # TODO: find a better solution
    };
  };

  chosenMethod =
    lib.mkIf (cfg.method == "replaceRuntimeDependencies") methodReplace
    //
    lib.mkIf (cfg.method == "GBM_BACKENDS_PATH") methodBackend;

  common = {
    specialisation.stable-mesa.configuration = {
      system.nixos.tags = [ "stable-mesa" ];
      chaotic.mesa-git.enable = lib.mkForce false;
    };
  };
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

      method =
        lib.mkOption {
          type = lib.types.enum [
            "replaceRuntimeDependencies"
            "GBM_BACKENDS_PATH"
          ];
          default = "GBM_BACKENDS_PATH";
          example = "replaceRuntimeDependencies";
          description = ''
            There are three available methods to replace your video drivers system-wide:

            - GBM_BACKENDS_PATH: The default one that tricks any package linked against nixpkgs' libgbm to load our newer one;
            - replaceRuntimeDependencies: The second most recommended, which impurely replaces nixpkgs' libgbm with ours in the nix store (requires "--impure");
          '';
        };

      extraPackages = with lib; mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "with pkgs; [ mesa_git.opencl intel-media-driver intel-ocl vaapiIntel ]";
        description = mdDoc ''
          Additional packages to add to OpenGL drivers.
          This can be used to add OpenCL drivers, VA-API/VDPAU drivers etc.

          WARNING: Don't use any of the `mesa.*`, replace with `pkgs.mesa_git.*`.
        '';
      };

      extraPackages32 = with lib; mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "with pkgs.pkgsi686Linux; [ pkgs.mesa32_git.opencl intel-media-driver vaapiIntel ]";
        description = mdDoc ''
          Additional packages to add to 32-bit OpenGL drivers on 64-bit systems.

          WARNING: Don't use any of the `mesa.*`, replace with `pkgs.mesa32_git.*`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (common // chosenMethod);
}
