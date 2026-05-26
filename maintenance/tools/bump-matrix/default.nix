{
  lib,
  writeText,
  allPackages,
  nyxRecursionHelper,
}:
let
  inherit (lib.strings) escapeShellArg;
  inherit (lib.lists) flatten;

  evalResult = k: v: if ((v.updateScript or null) != null) then escapeShellArg k else null;

  skip =
    _k: _v: _message:
    null;

  packagesEval = nyxRecursionHelper.derivationsLimited 2 skip evalResult allPackages;

  packagesEvalSorted = builtins.filter (x: x != null) (flatten packagesEval);
in
writeText "chaotic-bump-matrix.json" (lib.generators.toJSON { } packagesEvalSorted)
