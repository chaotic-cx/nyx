{ all-packages
, compareTo ? compareToFlake.packages.${system}
, compareToFlake ? (builtins.getFlake compareToFlakeUrl)
, compareToFlakeUrl ? "github.com/chaotic-cx/nix-empty-flake"
, derivationRecursiveFinder
, lib
, system
, writeText
}:
let
  evalResult = k: v:
    { name = k; value = builtins.unsafeDiscardStringContext v.outPath; };

  warn = k: _: message:
    { name = k; value = message; };

  packagesEval = packages:
    lib.lists.flatten (derivationRecursiveFinder.eval warn evalResult packages);

  compareToEvalSet = builtins.listToAttrs (packagesEval compareTo);

  onlyNewPackages = builtins.filter
    ({ name, value }:
      value != (compareToEvalSet.${name} or null)
    )
    (packagesEval all-packages);

  onlyNewPackagesNames = lib.attrsets.catAttrs "name" onlyNewPackages;
in
writeText "packages-diff.txt"
  (lib.strings.concatStringsSep "\n" onlyNewPackagesNames)
