{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "openmohaa_git";
  versionNyxPath = "pkgs/openmohaa-git/version.json";
  versionLocalPath = ./version.json;
  prev = final.openmohaa;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "openmoh";
      repo = "openmohaa";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "main"; };
  hasSubmodules = true;
}
