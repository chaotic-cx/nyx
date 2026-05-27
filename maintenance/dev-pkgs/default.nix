base:
{
  flakes,
  homeManagerModules ? self.homeManagerModules,
  nixpkgs ? flakes.nixpkgs,
  home-manager ? flakes.home-manager,
  niks3 ? flakes.niks3,
  packages ? self._dev.legacyPackages,
  self ? flakes.self,
  nyxosConfiguration ? self._dev.system.x86_64-linux,
  applyOverlay ? self.utils.applyOverlay,
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkDevPackages =
    nyxPkgs: nixPkgs:
    let
      pkgs = applyOverlay {
        inherit nyxPkgs;
        pkgs = nixPkgs;
        replace = true;
        merge = true;
      };
      inherit (pkgs) callPackage;

      nyxRecursionHelper = callPackage ../../shared/recursion-helper.nix {
        inherit (pkgs.stdenv.hostPlatform) system;
      };

      # Matches build.yml and full-bump.yml
      pinnedNix = pkgs.nixVersions.latest;

    in
    rec {
      builder = callPackage ../tools/builder {
        nix = pinnedNix;
        inherit dry-build;
      };
      dry-build = callPackage ../tools/dry-build {
        allPackages = nyxPkgs;
        flakeSelf = self;
        inherit nyxRecursionHelper;
        inherit (pkgs) nyxUtils;
      };
      documentation = callPackage ../tools/document {
        allPackages = nyxPkgs;
        homeManagerModule = homeManagerModules.default;
        inherit
          nixpkgs
          nyxRecursionHelper
          self
          nyxosConfiguration
          ;
        inherit (home-manager.lib) homeManagerConfiguration;
      };
      compared = callPackage ../tools/comparer {
        allPackages = nyxPkgs;
        compareToFlake = flakes.compare-to;
        inherit nyxRecursionHelper;
      };
      bump-matrix = callPackage ../tools/bump-matrix {
        inherit dry-build;
      };
      linter = callPackage ../tools/linter {
        formatter = self.formatter.${pkgs.stdenv.hostPlatform.system};
      };
    };

  mkDevPackagesSet = nyxPkgs: nixPkgs: {
    chaotic-nyx = mkDevPackages nyxPkgs nixPkgs;
    inherit (niks3.packages.${nixPkgs.stdenv.hostPlatform.system}) niks3;
  };
in
base
// {
  x86_64-linux =
    base.x86_64-linux // (mkDevPackagesSet packages.x86_64-linux nixpkgs.legacyPackages.x86_64-linux);
  aarch64-linux =
    base.aarch64-linux
    // (mkDevPackagesSet packages.aarch64-linux nixpkgs.legacyPackages.aarch64-linux);
  aarch64-darwin =
    base.aarch64-darwin
    // (mkDevPackagesSet packages.aarch64-darwin nixpkgs.legacyPackages.aarch64-darwin);
}
