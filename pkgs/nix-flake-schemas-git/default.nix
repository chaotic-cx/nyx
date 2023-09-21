{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nix-flake-schemas_git";
  versionNyxPath = "pkgs/nix-flake-schemas-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.nix;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "DeterminateSystems";
      repo = "nix";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "flake-schemas"; };

  postOverrides = [
    (prevAttrs: {
      doInstallCheck = false;
      meta = prevAttrs.meta // {
        homepage = "https://determinate.systems/posts/flake-schemas";
        description = "Nix from the branch with flake-schemas";
        longDescription = prevAttrs.meta.longDescription + "(from the branch with flake-schemas).";
      };
    })
  ];
}
