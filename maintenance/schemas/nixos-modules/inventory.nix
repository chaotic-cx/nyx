{ nyxosConfiguration
, pkgs
, lib ? pkgs.lib
}: _output:
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

  nixosEval = nyxRecursionHelper.options optionWarn optionMap nyxosConfiguration.options.chaotic;

  nixosEvalFlat =
    lib.lists.flatten nixosEval;
in
{
  children.default.children =
    builtins.listToAttrs nixosEvalFlat;
}
