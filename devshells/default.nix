{ inputs
, nixpkgs ? inputs.nixpkgs
, packages
, self ? inputs.self
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
      evaluated = overlayFinal.callPackage ./eval.nix
        {
          all-packages = final;
          inherit derivationRecursiveFinder;
        };
      compared = overlayFinal.callPackage ./comparer.nix
        {
          packagesA = final;
          compareToFlake = inputs.compare-to;
          inherit derivationRecursiveFinder;
        };
    in
    {
      default = overlayFinal.mkShell {
        buildInputs = [ builder ];
      };
      evaluator = overlayFinal.mkShell { env.NYX_EVALUATED = evaluated; };
      comparor = overlayFinal.mkShell { env.NYX_COMPARED = compared; };
    };
in
{
  x86_64-linux = mkShells packages.x86_64-linux
    nixpkgs.legacyPackages.x86_64-linux;
  aarch64-linux = mkShells packages.aarch64-linux
    nixpkgs.legacyPackages.aarch64-linux;
}
