{ allPackages
, nyxRecursionHelper
, lib
, writeShellScriptBin
}:
let
  evalResult = k: v:
    if ((v.updateScript or null) != null) then
      if (builtins.isList v.updateScript) then
        "${lib.strings.concatStringsSep " && " v.updateScript} # ${k}"
      else
        "${v.updateScript} # ${k}"
    else null;

  skip = _k: _v: _message: null;

  packagesEval = nyxRecursionHelper.derivationsLimited 2 skip evalResult allPackages;

  packagesEvalSorted =
    builtins.filter (f: f != null) (lib.lists.flatten packagesEval);
in
writeShellScriptBin "chaotic-nyx-update-scripts"
  (lib.strings.concatStringsSep "\n" packagesEvalSorted)
