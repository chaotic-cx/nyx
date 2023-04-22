{ lib, callPackage }:
rec {
  unreachableHash = "sha256-2342234223422342234223422342234223422342069=";

  derivationRecursiveFinder = callPackage ../shared/derivation-recursive-finder.nix { };

  dropN = n: list: lib.lists.take (builtins.length list - n) list;

  drvElem = x: xs:
    builtins.elem x.drvPath (builtins.map (xsx: xsx.drvPath) xs);

  drvHash = drv:
    builtins.substring 0 32 (builtins.baseNameOf (builtins.unsafeDiscardStringContext drv.drvPath));

  internalDeps = packages: drv:
    let
      allDeps = lib.strings.concatStringsSep " "
        (builtins.attrNames (builtins.getContext (builtins.toJSON (drv.drvAttrs))));
    in
    builtins.filter (x: lib.strings.hasInfix (builtins.unsafeDiscardStringContext x.drvPath) allDeps) packages;

  gitToVersion = src: "unstable-${src.lastModifiedDate}-${src.shortRev}";

  gitOverride = src: drv:
    drv.overrideAttrs (_: {
      version = gitToVersion src;
      inherit src;
    });

  # We don't want builders playing around here.
  recurseForDerivations = false;
}
