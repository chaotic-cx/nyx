{ allPackages
, nyxRecursionHelper
, flakeSelf
, lib
, nyxUtils
, writeText
, hostPlatform
}:

let
  allPackagesList =
    builtins.map (xsx: xsx.drv)
      (lib.lists.filter (xsx: xsx.drv != null) packagesEval);

  inherit (hostPlatform) system;

  brokenOutPaths = builtins.attrValues (import "${flakeSelf}/maintenance/failures.${system}.nix");

  allOuts = key: drv:
    let
      pair = output: {
        name = nyxRecursionHelper.join key output;
        value = builtins.unsafeDiscardStringContext drv.${output}.outPath;
      };
    in
    builtins.listToAttrs (map pair drv.outputs);

  derivationMap = key: drv:
    let
      deps = nyxUtils.internalDeps allPackagesList drv;
      depsCond = builtins.map (dep: nyxUtils.drvHash dep) deps;
      mainOutPath = builtins.unsafeDiscardStringContext drv.outPath;
      thisVar = nyxUtils.drvHash drv;
    in
    if builtins.elem mainOutPath brokenOutPaths then
      doNotBuild key { broken = mainOutPath; inherit system; }
    else
      {
        cmd = {
          build = true;
          artifacts = allOuts key drv;
          deps = depsCond;
          this = thisVar;
          inherit key mainOutPath system;
        };
        inherit deps drv;
      };

  commentWarn = key: _v: message:
    doNotBuild key { warn = message; };

  doNotBuild = key: data:
    {
      cmd = {
        build = false;
        inherit key;
      } // data;
      drv = null;
      deps = [ ];
    };

  packagesEval =
    lib.lists.flatten
      (nyxRecursionHelper.derivations commentWarn derivationMap allPackages);

  depFirstSorter = pkgA: pkgB:
    if pkgA.drv == null || pkgB.drv == null then
      false
    else
      nyxUtils.drvElem pkgA.drv pkgB.deps;

  packagesEvalSorted =
    lib.lists.toposort depFirstSorter packagesEval;

  packagesCmds =
    builtins.map (pkg: pkg.cmd) packagesEvalSorted.result;

  finalJSON = writeText "chaotic-dry-build.json" (lib.generators.toJSON { } packagesCmds);
in
finalJSON.overrideAttrs (oldAttrs: {
  passthru = (oldAttrs.passthru or { }) // {
    inherit packagesCmds system flakeSelf;
  };
})
