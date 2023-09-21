{ flakes
, homeManagerConfiguration ? flakes.home-manager.lib.homeManagerConfiguration
, pkgs
, lib ? pkgs.lib
}: output:
let
  nyxRecursionHelper = pkgs.callPackage ../../../shared/recursion-helper.nix { };

  optionMap = k: v:
    {
      name = "chaotic.${k}";
      value.what =
        builtins.replaceStrings [ "\n" "\t" ] [ " " " " ] v.description;
    };

  optionWarn = k: _v: message:
    { name = "chaotic.${k}"; value.what = "(${message})"; };

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
