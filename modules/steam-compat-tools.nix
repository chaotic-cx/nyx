{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.steam;
in {
  options.programs.steam = {
    extraCompatPackages = mkOption {
      type = with types; listOf package;
      default = [];
      defaultText = literalExpression "[]";
      example = literalExpression ''
        with pkgs; [
          luxtorpeda
          proton-ge
        ]
      '';
      description = lib.mdDoc ''
        Extra packages to be used as compatibility tools for Steam on Linux. Packages will be included
        in the `STEAM_EXTRA_COMPAT_TOOLS_PATHS` environmental variable. For more information see
        <https://github.com/ValveSoftware/steam-for-linux/issues/6310">.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Append the extra compatibility packages to whatever else the env variable was populated with.
    # For more information see https://github.com/ValveSoftware/steam-for-linux/issues/6310.
    environment.sessionVariables = mkIf (cfg.extraCompatPackages != []) {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = makeBinPath cfg.extraCompatPackages;
    };
  };
}
