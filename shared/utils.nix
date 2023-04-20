{ lib, callPackage }:
rec {
  derivationRecursiveFinder = callPackage ../shared/derivation-recursive-finder.nix { };

  dropN = n: list: lib.lists.take (builtins.length list - n) list;

  drvElem = x: xs:
    builtins.elem x.drvPath (builtins.map (xsx: xsx.drvPath) xs);

  drvHash = drv:
    builtins.substring 0 32 (builtins.baseNameOf (builtins.unsafeDiscardStringContext drv.drvPath));

  drvInputs = drv:
    (drv.paths or [ ]) ++ (drv.buildInputs or [ ]);

  internalDeps = packagesOutPaths: drv:
    let
      recursive = input:
        if builtins.isAttrs input then
          if builtins.elem input.drvPath packagesOutPaths then
            input
          else
            builtins.map recursive (drvInputs input)
        else [ ];
    in
    lib.lists.unique (lib.lists.flatten (builtins.map recursive (drvInputs drv)));

  gitToVersion = src: "unstable-${src.lastModifiedDate}-${src.shortRev}";

  gitOverride = src: drv:
    drv.overrideAttrs (_: {
      version = gitToVersion src;
      inherit src;
    });

  # We don't want builders playing around here.
  recurseForDerivations = false;
}
