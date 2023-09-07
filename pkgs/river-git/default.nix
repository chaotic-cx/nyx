{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "river_git";
  versionNyxPath = "pkgs/river-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.river;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "riverwm";
      repo = "river";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
  hasSubmodules = true;
}
