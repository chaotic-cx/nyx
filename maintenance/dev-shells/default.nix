{ flakes
, homeManagerModules ? self.homeManagerModules
, nixpkgs ? flakes.nixpkgs
, home-manager ? flakes.home-manager
, packages ? self.packages
, self ? flakes.self
, nyxosConfiguration ? self._dev.x86_64-linux
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells = final: prev:
    let
      overlayFinal = prev // final // { callPackage = prev.newScope final; };

      nyxRecursionHelper = overlayFinal.callPackage ../../shared/recursion-helper.nix { };

      builder = overlayFinal.callPackage ../tools/builder
        {
          allPackages = final;
          flakeSelf = self;
          inherit nyxRecursionHelper;
          inherit (overlayFinal) nyxUtils;
        };
      documentation = overlayFinal.callPackage ../tools/document
        {
          allPackages = final;
          homeManagerModule = homeManagerModules.default;
          inherit nixpkgs nyxRecursionHelper self nyxosConfiguration;
          inherit (home-manager.lib) homeManagerConfiguration;
        };
      evaluated = overlayFinal.callPackage ../tools/eval
        {
          allPackages = final;
          inherit nyxRecursionHelper;
        };
      compared = overlayFinal.callPackage ../tools/comparer
        {
          allPackages = final;
          compareToFlake = flakes.compare-to;
          inherit nyxRecursionHelper;
        };
      comparer = compareToFlakeUrl: overlayFinal.callPackage ../tools/comparer
        {
          allPackages = final;
          inherit compareToFlakeUrl nyxRecursionHelper;
        };
      update-scripts = overlayFinal.callPackage ../tools/bumper/update-scripts
        {
          allPackages = final;
          inherit nyxRecursionHelper;
        };
      bumper = overlayFinal.callPackage ../tools/bumper
        {
          inherit update-scripts;
        };
      linter = overlayFinal.callPackage ../tools/linter { };
    in
    {
      default = overlayFinal.mkShell {
        buildInputs = [ builder ];
      };
      document = overlayFinal.mkShell {
        env.NYX_DOCUMENTATION = documentation;
        shellHook = "echo $NYX_DOCUMENTATION";
      };
      evaluator = overlayFinal.mkShell {
        env.NYX_EVALUATED = evaluated;
        shellHook = "echo $NYX_EVALUATED";
      };
      comparer = overlayFinal.mkShell {
        passthru.any = comparer;
        env.NYX_COMPARED = compared;
        shellHook = "echo $NYX_COMPARED";
      };
      updater = overlayFinal.mkShell {
        buildInputs = [ update-scripts bumper ];
      };
      linter = overlayFinal.mkShell {
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
