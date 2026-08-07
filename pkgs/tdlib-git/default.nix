{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "tdlib_git";
  prev = prev.tdlib;

  manifestPath = "pkgs/tdlib-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "tdlib";
    repo = "td";
  };
  ref = "master";
}
