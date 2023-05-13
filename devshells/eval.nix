{ all-packages
, derivationRecursiveFinder
, lib
, nyxUtils
, system
, writeText
}:
let
  evalResult = k: v:
    "${system}\t${k}\t${nyxUtils.drvHash v}\t${builtins.unsafeDiscardStringContext v.outPath}";

  warn = k: _: message:
    "${system}\t${k}\t_\t${message}";

  packagesEval = derivationRecursiveFinder.eval warn evalResult all-packages;

  packagesEvalSorted =
    lib.lists.naturalSort (lib.lists.flatten packagesEval);
in
writeText "chaotic-nyx-eval.tsv"
  (lib.strings.concatStringsSep "\n" packagesEvalSorted)
