{ inputs }: { config, options, lib, pkgs, ... }:
let
  cfg = config.chaotic.nyx.overlay;
  cacheCfg = config.chaotic.nyx.cache;
  stdenv = pkgs.stdenv;

  onTopOfFlakeInputs =
    _: userPrev:
    let
      isCross = stdenv.buildPlatform != stdenv.hostPlatform;

      prev =
        if isCross then
          import "${inputs.nixpkgs}"
            {
              inherit (cfg.flakeNixpkgs) config;
              localSystem = stdenv.buildPlatform;
              crossSystem = stdenv.hostPlatform;
            }
        else
          import "${inputs.nixpkgs}" {
            inherit (cfg.flakeNixpkgs) config;
            localSystem = stdenv.hostPlatform;
          };

      overlayFinal = prev // ourPackages // { callPackage = prev.newScope overlayFinal; };
      ourPackages = inputs.self.overlays.default overlayFinal prev;
    in
    ourPackages;

  onTopOfUserPkgs =
    inputs.self.overlays.default;
in
{
  options = {
    chaotic.nyx.overlay = {
      enable =
        lib.mkOption {
          default = true;
          description = ''
            Whether to add Chaotic-Nyx's overlay to system's pkgs.
          '';
        };
      onTopOf =
        lib.mkOption {
          type = lib.types.enum [ "flake-nixpkgs" "user-pkgs" ];
          default = "flake-nixpkgs";
          example = "user-pkgs";
          description = ''
            Build Chaotic-Nyx's packages based on nyx's flake inputs or the system's pkgs.
          '';
        };
      flakeNixpkgs.config = lib.mkOption {
        default = pkgs.config;
        inherit (options.nixpkgs.config) example type;
        description = lib.mdDoc ''
          Matches `nixpkgs.config` from the configuration of the Nix Packages collection.
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays =
      if cfg.onTopOf == "flake-nixpkgs" then [
        onTopOfFlakeInputs
      ] else [
        onTopOfUserPkgs
      ];

    warnings =
      lib.mkIf (cfg.onTopOf == "user-pkgs" && cacheCfg.enable) [
        ''Chaotic Nyx certainly won't hit cache when using `chaotic.nyx.overlay = "user-pkgs"`.''
      ];
  };
}
