{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "waynergy_git";
  versionNyxPath = "pkgs/waynergy-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.waynergy;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "r-c-f";
      repo = "waynergy";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
}
