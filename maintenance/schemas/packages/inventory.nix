{ nixpkgs }: output:
let
  mkPackages = system: nyxPkgs:
    let
      inherit (nixpkgs) lib;

      nyxRecursionHelper = import ../../../shared/recursion-helper.nix { inherit lib system; };

      derivationMap = k: v:
        {
          name = k;
          value = {
            what = "package";
            forSystems = [ v.system ];
            shortDescription = v.meta.description or "N/A";
            derivation = v;
            #evalChecks.isDerivation = true;
          };
        };

      derivationWarn = k: v: message:
        if message == "unfree" then derivationMap k v
        else if message == "not a derivation" && ((v._description or null) == null) then null
        else {
          name = k;
          value = {
            what = message;
            shortDescription = v._description or "N/A";
            #evalChecks.isDerivation = false;
          };
        };

      packagesEval = nyxRecursionHelper.derivations derivationWarn derivationMap nyxPkgs;

      packagesEvalFlat =
        lib.lists.remove null (lib.lists.flatten packagesEval);

    in
    builtins.listToAttrs packagesEvalFlat;

  removeAlias = attrs:
    builtins.removeAttrs attrs
      [
        "linuxPackages_cachyos-sched-ext"
      ];
in
{
  children = {
    x86_64-linux.forSystems = [ "x86_64-linux" ];
    x86_64-linux.children =
      mkPackages "x86_64-linux" (removeAlias output.x86_64-linux);
    aarch64-linux.forSystems = [ "aarch64-linux" ];
    aarch64-linux.children =
      let
        # When on aarch64 we don't need to expose *32 packages
        removeCross = import ./remove-cross-stuff.nix;
      in
      mkPackages "aarch64-linux" (removeCross (removeAlias output.aarch64-linux));
  };
}
