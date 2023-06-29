{ all-packages
, derivationRecursiveFinder
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

  skip = _: _: _: null;

  packagesEval = derivationRecursiveFinder.evalLimited 1 skip evalResult all-packages;

  packagesEvalSorted =
    builtins.filter (f: f != null) (lib.lists.flatten packagesEval);
in
writeShellScriptBin "chaotic-nyx-update-scripts"
  (lib.strings.concatStringsSep "\n" packagesEvalSorted)
