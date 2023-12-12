{ nyxosConfiguration
, pkgs
, lib ? pkgs.lib
}: _output:
let
  shared = import ../shared/options.nix;
  inherit (shared) optionMap optionWarn;

  nyxRecursionHelper = pkgs.callPackage ../../../shared/recursion-helper.nix { inherit (pkgs.stdenv) system; };

  nixosEval = nyxRecursionHelper.options optionWarn optionMap nyxosConfiguration.options.chaotic;

  nixosEvalFlat =
    lib.lists.flatten nixosEval;
in
{
  children.default.children =
    builtins.listToAttrs nixosEvalFlat;
}
