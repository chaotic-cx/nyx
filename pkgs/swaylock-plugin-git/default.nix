{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "swaylock-plugin_git";
  versionNyxPath = "pkgs/swaylock-plugin-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.swaylock;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "mstoeckl";
      repo = "swaylock-plugin";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "main"; };
}
