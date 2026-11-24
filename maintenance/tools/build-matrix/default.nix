{
  lib,
  writeText,
  builder,
  allPackages,
  nyxUtils,
  prebuiltTargets ? [ ],
}:
let
  inherit (builder.passthru.dry-build.passthru) groupBuildable groupedBuildable packagesCmds;

  prebuilt = map (
    target: nyxUtils.drvHash (lib.getAttrFromPath (lib.splitString "." target) allPackages)
  ) prebuiltTargets;

  dependents = builtins.filter (
    cmd:
    cmd.build
    && !(builtins.elem cmd.this prebuilt)
    && lib.any (dep: builtins.elem dep prebuilt) cmd.deps
  ) packagesCmds;
  dependentHashes = map (cmd: cmd.this) dependents;

  # Nix resolves dependencies outside the matrix. Only keep edges between jobs we schedule.
  dependentGroups = groupBuildable (
    map (
      cmd: cmd // { deps = builtins.filter (dep: builtins.elem dep dependentHashes) cmd.deps; }
    ) dependents
  );

  getBuildCmds = xs: (builder.override { subset = xs; }).passthru.packagesCmds;

  groupedPackagesCmds = builtins.map (xs: lib.strings.concatStringsSep "\n" (getBuildCmds xs)) (
    if prebuiltTargets == [ ] then groupedBuildable else dependentGroups
  );
in
writeText "chaotic-build-matrix.json" (lib.generators.toJSON { } groupedPackagesCmds)
