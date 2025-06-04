{
  config,
  lib,
  ...
}:
# I don't use "nix-ld", but I wrote this to a friend and didn't want it to go to waste
let
  cfg = config.chaotic.nix-ld;
in
{
  options = with lib; {
    chaotic.nix-ld.addSystemDependencies = mkOption {
      default = false;
      example = true;
      type = types.bool;
      description = ''
        Add all direct dependencies from your `environment.systemPackages` to `programs.nix-ld.libraries`.

        This does not include the apps/packages themselves, nor the dependencies of their dependencies.
      '';
    };
  };
  config = lib.mkIf cfg.addSystemDependencies {
    programs.nix-ld.libraries =
      let
        fromApp = drv: drv.buildInputs ++ (drv.runtimeDependencies or [ ]);

        cleanup = builtins.filter (x: x != null);

        systemDependencies = cleanup (builtins.concatLists (map fromApp config.environment.systemPackages));

        unique =
          drvs: map builtins.head (builtins.attrValues (builtins.groupBy (drv: drv.pname or drv.name) drvs));
      in
      unique systemDependencies;
  };
}
