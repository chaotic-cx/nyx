{
  lib,
  writeText,
  dry-build,
}:
let
  inherit (dry-build.passthru) groupedBuildable;

  filteredGroups = map (builtins.filter (xs: xs.updatable)) groupedBuildable;

  updatableGroups = builtins.filter (xs: xs != [ ]) filteredGroups;

  groupedUpdatableKeys = map (map (x: x.key)) updatableGroups;
in
writeText "chaotic-bump-matrix.json" (lib.generators.toJSON { } groupedUpdatableKeys)
