{
  writeText,
  allSystems,
}:
let
  packagesCmds = builtins.concatMap (dry-build: dry-build.passthru.packagesCmds) (
    builtins.attrValues allSystems
  );

  filteredCmds = builtins.filter (packagesCmd: packagesCmd ? artifacts) packagesCmds;

  allPins = builtins.concatMap (
    { artifacts, system, ... }: map (key: "${system}.${key}") (builtins.attrNames artifacts)
  ) filteredCmds;
in
writeText "chaotic-expected-pins.txt" (builtins.concatStringsSep "\n" allPins)
