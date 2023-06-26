{ inputs }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic.mesa-git;

  has32 = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86;

  methodLD =
    let
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
    in
    {
      hardware.opengl = with lib; {
        enable = mkForce false;
        package = mkForce pkgs.mesa_git.out;
        package32 = mkForce pkgs.mesa32_git.out;
        extraPackages = mkForce [ ];
        extraPackages32 = mkForce [ ];
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
        [ "/run/opengl-driver/lib" ] ++ lib.optional has32 "/run/opengl-driver-32/lib";

      warnings = [
        "The current implementation of `chaotic.mesa-git` is known to cause problems with Steam and apps with wrappers preloading Mesa (e.g., Firefox). A refactor of this module is currently in development."
      ];
    };

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

  vendoredGBM = pkgs.callPackage
    ({ stdenvNoCC, mesa }: stdenvNoCC.mkDerivation {
      pname = "mesa-libgbm";
      version = "0.0.0";
      src = mesa;
      installPhase = ''
        mkdir -p $out/lib/gbm
        ln -s lib/libgbm.so $out/lib/gbm/dri_gbm.so
      '';
    })
    { mesa = pkgs.mesa_git; };

  methodBackend = {
    hardware.opengl = with lib; {
      enable = mkForce true;
      package = mkForce pkgs.mesa_git.drivers;
      package32 = mkForce pkgs.mesa32_git.drivers;
      extraPackages = mkForce (cfg.extraPackages ++ [ vendoredGBM ]);
      extraPackages32 = mkForce cfg.extraPackages32;
      driSupport = mkForce true;
      driSupport32Bit = mkForce has32;
      setLdLibraryPath = mkForce false;
    };

    environment.sessionVariables = {
      GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
      GBM_BACKEND = "dri";
    };
  };

  chosenMethod =
    if cfg.method == "LD_LIBRARY_PATH" then
      methodLD
    else if cfg.method == "replaceRuntimeDependencies" then
      methodReplace
    else methodBackend;

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
            "LD_LIBRARY_PATH"
            "replaceRuntimeDependencies"
            "GBM_BACKENDS_PATH"
          ];
          default = "GBM_BACKENDS_PATH";
          example = "LD_LIBRARY_PATH";
          description = ''
            TODO
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
