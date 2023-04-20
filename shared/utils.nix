{ lib, callPackage }:
rec {
  derivationRecursiveFinder = callPackage ../shared/derivation-recursive-finder.nix { };

  dropN = n: list: lib.lists.take (builtins.length list - n) list;

  gitToVersion = src: "unstable-${src.lastModifiedDate}-${src.shortRev}";

  gitOverride = src: drv:
    drv.overrideAttrs (_: {
      version = gitToVersion src;
      inherit src;
    });

  # We don't want builders playing around here.
  recurseForDerivations = false;
}
