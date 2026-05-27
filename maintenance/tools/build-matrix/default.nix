{
  lib,
  writeText,
  builder,
}:
let
  inherit (builder.passthru.dry-build.passthru) groupedBuildable;

  getBuildCmds = xs: (builder.override { subset = xs; }).passthru.packagesCmds;

  groupedPackagesCmds = builtins.map (
    xs: lib.strings.concatStringsSep "\n" (getBuildCmds xs)
  ) groupedBuildable;
in
writeText "chaotic-build-matrix.json" (lib.generators.toJSON { } groupedPackagesCmds)
