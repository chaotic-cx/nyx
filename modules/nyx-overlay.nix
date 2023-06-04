{ inputs }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic.nyx.overlay;
  cacheCfg = config.chaotic.nyx.cache;

  onTopOfFlakeInputs =
    (_: userPrev:
      let
        input = inputs.nixpkgs.legacyPackages.${pkgs.system};
        ourPackages = inputs.self.overlays.default (input // ourPackages) input;
      in
      userPrev // ourPackages
    );

  onTopOfUserPkgs =
    [ inputs.self.overlays.default ];
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
          type = lib.types.either "flake-nixpkgs" "user-pkgs";
          default = "flake-nixpkgs";
          example = "user-pkgs";
          description = ''
            Build Chaotic-Nyx's packages based on nyx's flake inputs or the system's pkgs.
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
