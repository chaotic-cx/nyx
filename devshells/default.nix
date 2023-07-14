{ flakes
, nixpkgs ? flakes.nixpkgs
, packages
, self ? flakes.self
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells = final: prev:
    let
      overlayFinal = prev // final // { callPackage = prev.newScope final; };

      derivationRecursiveFinder = overlayFinal.callPackage ./derivation-recursive-finder.nix { };

      builder = overlayFinal.callPackage ./builder.nix
        {
          all-packages = final;
          flakeSelf = self;
          inherit derivationRecursiveFinder;
          inherit (overlayFinal) nyxUtils;
        };
      documentation = overlayFinal.callPackage ./document.nix
        {
          all-packages = final;
          inherit derivationRecursiveFinder;
        };
      evaluated = overlayFinal.callPackage ./eval.nix
        {
          all-packages = final;
          inherit derivationRecursiveFinder;
        };
      compared = overlayFinal.callPackage ./comparer.nix
        {
          all-packages = final;
          compareToFlake = flakes.compare-to;
          inherit derivationRecursiveFinder;
        };
      comparer = compareToFlakeUrl: overlayFinal.callPackage ./comparer.nix
        {
          all-packages = final;
          inherit compareToFlakeUrl derivationRecursiveFinder;
        };
      update-scripts = overlayFinal.callPackage ./bumper/update-scripts.nix
        {
          all-packages = final;
          inherit derivationRecursiveFinder;
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
