{ nixpkgs }: output:
let
  mkPackages = nyxPkgs:
    let
      inherit (nixpkgs) lib;

      nyxRecursionHelper = import ../../../shared/recursion-helper.nix { inherit lib; };

      derivationMap = k: v:
        {
          name = k;
          value = {
            what = "package";
            forSystems = [ v.system ];
            shortDescription = v.meta.description or "N/A";
            derivation = v;
            evalChecks.isDerivation = true;
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
            evalChecks.isDerivation = false;
          };
        };

      packagesEval = nyxRecursionHelper.derivationsLimited "explicit" derivationWarn derivationMap nyxPkgs;

      packagesEvalFlat =
        lib.lists.remove null (lib.lists.flatten packagesEval);

    in
    builtins.listToAttrs packagesEvalFlat;
in
{
  children = {
    x86_64-linux.forSystems = [ "x86_64-linux" ];
    x86_64-linux.children =
      mkPackages output.x86_64-linux;
    aarch64-linux = {
      forSystems = [ "aarch64-linux" ];
      what = "broken";
      evalChecks.isDerivation = false;
      #children =
      #  mkPackages output.aarch64-linux
      #    nixpkgs.legacyPackages.aarch64-linux;
    };
  };
}
