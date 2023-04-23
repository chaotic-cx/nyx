{ packagesA
, packagesB ? compareTo.packages.${system}
, compareTo ? (builtins.getFlake "github.com/chaotic-cx/nix-empty-flake")
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

  packagesBEvalSet = builtins.listToAttrs (packagesEval packagesB);

  onlyNewPackages = builtins.filter
    ({ name, value }:
      value != (packagesBEvalSet.${name} or null)
    )
    (packagesEval packagesA);

  onlyNewPackagesNames = lib.attrsets.catAttrs "name" onlyNewPackages;
in
writeText "packages-diff.txt"
  (lib.strings.concatStringsSep "\n" onlyNewPackagesNames)
