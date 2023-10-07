{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "river_git";
  prev = prev.river;

  versionNyxPath = "pkgs/river-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "riverwm";
    repo = "river";
    fetchSubmodules = true;
  };
  ref = "master";
}
