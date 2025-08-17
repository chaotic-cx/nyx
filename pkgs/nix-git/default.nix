{ final, flakes, ... }:

let
  current = final.lib.importJSON ./version.json;

  versionDate = builtins.substring 0 8 current.lastModifiedDate;
  versionRev = builtins.substring 0 8 current.rev;
  version = "2.99pre${versionDate}_${versionRev}";

  src = final.fetchFromGitHub {
    owner = "NixOS";
    repo = "nix";
    inherit (current) rev hash;
  };

  addFixes = _finalScope: prevScope: {
    nix-store-tests = prevScope.nix-store-tests.overrideAttrs (prevAttrs: {
      # I guess the "optionalString" in the derivation is missing a NOT in the predicate
      passthru = prevAttrs.passthru // {
        tests = prevAttrs.passthru.tests // {
          run = prevAttrs.passthru.tests.run.overrideAttrs (testPrevAttrs: {
            buildCommand = ''
              export HOME="$PWD/home-dir"
              mkdir -p "$HOME"
            ''
            + testPrevAttrs.buildCommand;
          });
        };
      };
    });
  };

  nixComponents_git =
    (final.nixDependencies.callPackage
      "${flakes.nixpkgs}/pkgs/tools/package-management/nix/modular/packages.nix"
      rec {
        inherit version src;
        maintainers = [ final.lib.maintainers.pedrohlc ];
        teams = [ ];
        otherSplices = final.generateSplicesForNixComponents "nixComponents_git";
      }
    ).overrideScope
      addFixes;

in
nixComponents_git.nix-everything.overrideAttrs (prevAttrs: {
  passthru = prevAttrs.passthru // {
    components = nixComponents_git;
    updateScript = final.callPackage ../../shared/git-update.nix {
      inherit (prevAttrs) pname;
      nyxKey = "nix_git";
      versionPath = "pkgs/nix-git/version.json";
      fetchLatestRev = final.callPackage ../../shared/github-rev-fetcher.nix { } "master" src;
      gitUrl = src.gitRepoUrl;
      withLastModifiedDate = true;
    };
  };
})
