{
  lib,
  writeText,
  dry-build,
}:
let
  inherit (dry-build.passthru) groupedBuildable;

  updatableGroups = builtins.filter (xs: xs != [ ]) groupedBuildable;

  groupedUpdatableKeys = builtins.map (builtins.map (x: x.key)) updatableGroups;
in
writeText "chaotic-bump-matrix.json" (lib.generators.toJSON { } groupedUpdatableKeys)
