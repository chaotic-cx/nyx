{ flakes
, nixosModules
, nixpkgs ? flakes.nixpkgs
, packages
, self ? flakes.self
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells = final: prev:
    let
      overlayFinal = prev // final // { callPackage = prev.newScope final; };

      nyxRecursionHelper = overlayFinal.callPackage ../shared/recursion-helper.nix { };

      builder = overlayFinal.callPackage ./builder.nix
        {
          allPackages = final;
          flakeSelf = self;
          inherit nyxRecursionHelper;
          inherit (overlayFinal) nyxUtils;
        };
      documentation = overlayFinal.callPackage ./document.nix
        {
          allPackages = final;
          defaultModule = nixosModules.default;
          inherit nyxRecursionHelper;
        };
      evaluated = overlayFinal.callPackage ./eval.nix
        {
          allPackages = final;
          inherit nyxRecursionHelper;
        };
      compared = overlayFinal.callPackage ./comparer.nix
        {
          allPackages = final;
          compareToFlake = flakes.compare-to;
          inherit nyxRecursionHelper;
        };
      comparer = compareToFlakeUrl: overlayFinal.callPackage ./comparer.nix
        {
          allPackages = final;
          inherit compareToFlakeUrl nyxRecursionHelper;
        };
      update-scripts = overlayFinal.callPackage ./bumper/update-scripts.nix
        {
          allPackages = final;
          inherit nyxRecursionHelper;
        };
      bumper = overlayFinal.callPackage ./bumper
        {
          inherit update-scripts;
        };
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
    };
in
{
  x86_64-linux = mkShells packages.x86_64-linux
    nixpkgs.legacyPackages.x86_64-linux;
  aarch64-linux = mkShells packages.aarch64-linux
    nixpkgs.legacyPackages.aarch64-linux;
}
