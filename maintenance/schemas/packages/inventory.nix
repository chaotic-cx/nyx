{ nixpkgs }: output:
let
  mkPackages = final: prev:
    let
      inherit (prev) lib;

      overlayFinal = prev // final // { callPackage = prev.newScope final; };

      nyxRecursionHelper = overlayFinal.callPackage ../../../shared/recursion-helper.nix { };

      derivationMap = k: v:
        { name = k; value.what = v.meta.description or "N/A"; };

      derivationWarn = k: v: message:
        if message == "unfree" then derivationMap k v
        else if message == "not a derivation" && ((v._description or null) == null) then null
        else {
          name = k;
          value.what = v._description or "(${message})";
        };

      packagesEval = nyxRecursionHelper.derivationsLimited "explicit" derivationWarn derivationMap final;

      packagesEvalFlat =
        lib.lists.remove null (lib.lists.flatten packagesEval);

    in
    builtins.listToAttrs packagesEvalFlat;
in
{
  children = {
    x86_64-linux.forSystems = [ "x86_64-linux" ];
    x86_64-linux.children =
      mkPackages output.x86_64-linux
        nixpkgs.legacyPackages.x86_64-linux;
    aarch64-linux.forSystems = [ "aarch64-linux" ];
    aarch64-linux.children =
      mkPackages output.aarch64-linux
        nixpkgs.legacyPackages.aarch64-linux;
  };
}
