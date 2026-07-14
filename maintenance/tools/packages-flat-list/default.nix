{
  lib,
  writeText,
  allPackages,
  nyxRecursionHelper,
}:
let
  derivationMap = k: _v: ''
    x86_64-linux."${k}" = legacyPackages.x86_64-linux.${k};
  '';

  derivationWarn =
    k: v: message:
    if message == "unfree" then derivationMap k v else null;

  packagesEval =
    nyxRecursionHelper.derivationsLimited "explicit" derivationWarn derivationMap
      allPackages;

  packagesEvalFlat = lib.lists.remove null (lib.lists.flatten packagesEval);
in
writeText "chaotic-horrendous-flat-packages-cache.nix" ''
  legacyPackages: {
    ${builtins.concatStringsSep "\n" packagesEvalFlat}
  }
''
