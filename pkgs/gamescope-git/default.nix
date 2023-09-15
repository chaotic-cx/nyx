{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "gamescope_git";
  versionNyxPath = "pkgs/gamescope-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.gamescope;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "ValveSoftware";
      repo = "gamescope";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
  hasSubmodules = true;
  postOverrides = [(_prevAttrs: { postUnpack = ""; })]; # erase wlroots replacement since we're fetching submodules.
}
