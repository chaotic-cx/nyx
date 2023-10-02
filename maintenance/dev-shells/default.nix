{ flakes
, homeManagerModules ? self.homeManagerModules
, nixpkgs ? flakes.nixpkgs
, home-manager ? flakes.home-manager
, packages ? self._dev.packages
, self ? flakes.self
, nyxosConfiguration ? self._dev.system.x86_64-linux
, applyOverlay ? self.utils.applyOverlay
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells = nyxPkgs: nixPkgs:
    let
      pkgs = applyOverlay { inherit nyxPkgs; pkgs = nixPkgs; replace = true; merge = true; };
      inherit (pkgs) callPackage mkShell;

      nyxRecursionHelper = callPackage ../../shared/recursion-helper.nix { };

      builder = callPackage ../tools/builder
        {
          allPackages = nyxPkgs;
          flakeSelf = self;
          inherit nyxRecursionHelper;
          inherit (pkgs) nyxUtils;
        };
      documentation = callPackage ../tools/document
        {
          allPackages = nyxPkgs;
          homeManagerModule = homeManagerModules.default;
          inherit nixpkgs nyxRecursionHelper self nyxosConfiguration;
          inherit (home-manager.lib) homeManagerConfiguration;
        };
      evaluated = callPackage ../tools/eval
        {
          allPackages = nyxPkgs;
          inherit nyxRecursionHelper;
        };
      compared = callPackage ../tools/comparer
        {
          allPackages = nyxPkgs;
          compareToFlake = flakes.compare-to;
          inherit nyxRecursionHelper;
        };
      comparer = compareToFlakeUrl: callPackage ../tools/comparer
        {
          allPackages = nyxPkgs;
          inherit compareToFlakeUrl nyxRecursionHelper;
        };
      update-scripts = callPackage ../tools/bumper/update-scripts.nix
        {
          allPackages = nyxPkgs;
          inherit nyxRecursionHelper;
        };
      bumper = callPackage ../tools/bumper
        {
          inherit update-scripts;
        };
      linter = callPackage ../tools/linter { };
    in
    {
      default = mkShell {
        buildInputs = [ builder ];
      };
      document = mkShell {
        env.NYX_DOCUMENTATION = documentation;
        shellHook = "echo $NYX_DOCUMENTATION";
      };
      evaluator = mkShell {
        env.NYX_EVALUATED = evaluated;
        shellHook = "echo $NYX_EVALUATED";
      };
      comparer = mkShell {
        passthru.any = comparer;
        env.NYX_COMPARED = compared;
        shellHook = "echo $NYX_COMPARED";
      };
      updater = mkShell {
        buildInputs = [ update-scripts bumper ];
      };
      linter = mkShell {
        buildInputs = [ linter ];
      };
    };
in
{
  x86_64-linux = mkShells packages.x86_64-linux
    nixpkgs.legacyPackages.x86_64-linux;
  aarch64-linux = mkShells packages.aarch64-linux
    nixpkgs.legacyPackages.aarch64-linux;
}
