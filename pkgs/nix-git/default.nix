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
    # nix-util's meson.build requires libzstd but nixpkgs doesn't include it
    nix-util = prevScope.nix-util.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.pkg-config ];
      buildInputs = prevAttrs.buildInputs ++ [ final.zstd ];
    });

    # nix-util-tests also requires libzstd
    nix-util-tests = prevScope.nix-util-tests.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.pkg-config ];
      buildInputs = prevAttrs.buildInputs ++ [ final.zstd ];
    });

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

    # Upstream Nix removed src/perl in commit 2c26a23a (PR #15783):
    # 1. nix-serve is deprecated, and Hydra CI was the only active user of Perl bindings
    # 2. Perl bindings have been moved to the Hydra repo, no longer part of Nix core
    # 3. Override this component as an empty package to avoid build errors with latest Nix git
    nix-perl-bindings = final.runCommand "nix-perl-bindings-disabled" { } ''
      mkdir -p $out
    '';
  };

  nixComponents_git =
    (final.nixDependencies.callPackage
      "${flakes.nixpkgs}/pkgs/tools/package-management/nix/modular/packages.nix"
      {
        inherit version src;
        teams = [ ];
        otherSplices = final.generateSplicesForNixComponents "nixComponents_git";
      }
    ).overrideScope
      addFixes;

in
nixComponents_git.nix-everything.overrideAttrs (prevAttrs: {
  # Disable all tests for this git version of Nix.
  # Setting doCheck=false on nix-everything prevents checkInputs (which include
  # nix-util-tests, nix-functional-tests, etc.) from being built and run.
  doCheck = false;
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
