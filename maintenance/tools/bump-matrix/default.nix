{
  lib,
  writeText,
  dry-build,
}:
let
  inherit (dry-build.passthru) groupedBuildable;

  filteredGroups = builtins.map (builtins.filter (xs: xs.updatable)) groupedBuildable;

  updatableGroups = builtins.filter (xs: xs != [ ]) filteredGroups;

  groupedUpdatableKeys = builtins.map (builtins.map (x: x.key)) updatableGroups;
in
writeText "chaotic-bump-matrix.json" (lib.generators.toJSON { } groupedUpdatableKeys)
