{ flakes }: { config, options, lib, pkgs, ... }:
let
  cfg = config.chaotic.nyx.overlay;
  cacheCfg = config.chaotic.nyx.cache;

  onTopOfFlakeInputs =
    _userFinal: _userPrev:
    let
      inherit (pkgs) stdenv;
      isCross = stdenv.buildPlatform != stdenv.hostPlatform;

      prev =
        if isCross then
          import "${flakes.nixpkgs}"
            {
              inherit (cfg.flakeNixpkgs) config;
              localSystem = stdenv.buildPlatform;
              crossSystem = stdenv.hostPlatform;
            }
        else
          import "${flakes.nixpkgs}" {
            inherit (cfg.flakeNixpkgs) config;
            localSystem = stdenv.hostPlatform;
          };
    in
    flakes.self.utils.applyOverlay { pkgs = prev; };

  onTopOfUserPkgs =
    flakes.self.overlays.default;
in
{
  options = with lib; {
    chaotic.nyx.overlay = {
      enable =
        mkOption {
          default = true;
          example = false;
          type = types.bool;
          description = ''
            Whether to add Chaotic-Nyx's overlay to system's pkgs.
          '';
        };
      onTopOf =
        mkOption {
          type = types.enum [ "flake-nixpkgs" "user-pkgs" ];
          default = "flake-nixpkgs";
          example = "user-pkgs";
          description = ''
            Build Chaotic-Nyx's packages based on nyx's flake flakes or the system's pkgs.
          '';
        };
      flakeNixpkgs.config = mkOption {
        default = pkgs.config;
        defaultText = literalExpression "pkgs.config";
        inherit (options.nixpkgs.config) example type;
        description = ''
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
