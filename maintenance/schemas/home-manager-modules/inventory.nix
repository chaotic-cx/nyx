{ flakes
, homeManagerConfiguration ? flakes.home-manager.lib.homeManagerConfiguration
, pkgs
, lib ? pkgs.lib
}: output:
let
  shared = import ../shared/options.nix;
  inherit (shared) optionMap optionWarn;

  nyxRecursionHelper = pkgs.callPackage ../../../shared/recursion-helper.nix { };

  loadedHomeManagerModule = homeManagerConfiguration {
    modules = [
      {
        nix.package = pkgs.nix;
        home = {
          stateVersion = "23.11";
          username = "player";
          homeDirectory = "/tmp";
        };
      }
      output.default
    ];
    inherit pkgs;
  };

  homeManagerEval = nyxRecursionHelper.options optionWarn optionMap loadedHomeManagerModule.options.chaotic;

  homeManagerEvalFlat =
    lib.lists.flatten homeManagerEval;

in
{
  children.default.children =
    builtins.listToAttrs homeManagerEvalFlat;
}
