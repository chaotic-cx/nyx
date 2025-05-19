{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "tdlib_git";
  prev = prev.tdlib;

  versionNyxPath = "pkgs/tdlib-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "tdlib";
    repo = "td";
  };
  ref = "master";
}
