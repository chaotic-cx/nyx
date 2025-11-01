{
  flakes,
  homeManagerModules ? self.homeManagerModules,
  nixpkgs ? flakes.nixpkgs,
  home-manager ? flakes.home-manager,
  packages ? self._dev.legacyPackages,
  self ? flakes.self,
  nyxosConfiguration ? self._dev.system.x86_64-linux,
  applyOverlay ? self.utils.applyOverlay,
}:

# The following shells are used to help our maintainers and CI/CDs.
let
  mkShells =
    nyxPkgs: nixPkgs:
    let
      pkgs = applyOverlay {
        inherit nyxPkgs;
        pkgs = nixPkgs;
        replace = true;
        merge = true;
      };
      inherit (pkgs) callPackage;

      mkShell =
        if nixPkgs.stdenv.isLinux then
          opts:
          pkgs.mkShell (
            opts
            // {
              env = (opts.env or { }) // {
                # as seen on https://nixos.wiki/wiki/Locales
                LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
              };
            }
          )
        else
          pkgs.mkShell;

      nyxRecursionHelper = callPackage ../../shared/recursion-helper.nix {
        inherit (pkgs.stdenv.hostPlatform) system;
      };

      # Matches build.yml and full-bump.yml
      pinnedNix = pkgs.nixVersions.latest;

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
      evaluated = callPackage ../tools/eval {
        allPackages = nyxPkgs;
        inherit nyxRecursionHelper;
      };
      compared = callPackage ../tools/comparer {
        allPackages = nyxPkgs;
        compareToFlake = flakes.compare-to;
        inherit nyxRecursionHelper;
      };
      bumper = callPackage ../tools/bumper {
        allPackages = nyxPkgs;
        nix = pinnedNix;
        flakeSelf = self;
        inherit nyxRecursionHelper nixpkgs;
      };
      linter = callPackage ../tools/linter {
        formatter = self.formatter.${pkgs.stdenv.hostPlatform.system};
      };
    in
    {
      default = mkShell {
        buildInputs = [ builder ];
      };
      dry-build = mkShell {
        env.NYX_DRY_BUILD = dry-build;
        shellHook = "echo $NYX_DRY_BUILD";
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
        env.NYX_COMPARED = compared;
        passthru = { inherit compared; };
        shellHook = "echo $NYX_COMPARED";
      };
      updater = mkShell {
        buildInputs = [ bumper ];
      };
      linter = mkShell {
        buildInputs = [ linter ];
      };
    };
in
{
  x86_64-linux = mkShells packages.x86_64-linux nixpkgs.legacyPackages.x86_64-linux;
  aarch64-linux = mkShells packages.aarch64-linux nixpkgs.legacyPackages.aarch64-linux;
  aarch64-darwin = mkShells packages.aarch64-darwin nixpkgs.legacyPackages.aarch64-darwin;
}
