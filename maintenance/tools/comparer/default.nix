{
  allPackages,
  compareToFlake ? (builtins.getFlake compareToFlakeUrl),
  compareToFlakeUrl ? "github.com/chaotic-cx/nix-empty-flake",
  nyxRecursionHelper,
  lib,
  system,
  writeText,
}:
let
  compareTo =
    with compareToFlake;
    utils.applyOverlay {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          nvidia.acceptLicense = true;
        };
      };
    };

  evalResult = k: v: {
    name = k;
    value = builtins.unsafeDiscardStringContext v.outPath;
  };

  warn = k: _v: message: {
    name = k;
    value = message;
  };

  packagesEval =
    packages: lib.lists.flatten (nyxRecursionHelper.derivations warn evalResult packages);

  compareToEvalSet = builtins.listToAttrs (packagesEval compareTo);

  onlyNewPackages = builtins.filter ({ name, value }: value != (compareToEvalSet.${name} or null)) (
    packagesEval allPackages
  );

  onlyNewPackagesNames = lib.attrsets.catAttrs "name" onlyNewPackages;
in
writeText "packages-diff.txt" (lib.strings.concatStringsSep "\n" onlyNewPackagesNames)
