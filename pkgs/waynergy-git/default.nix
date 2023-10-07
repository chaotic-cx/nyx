{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "waynergy_git";
  prev = prev.waynergy;

  versionNyxPath = "pkgs/waynergy-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "r-c-f";
    repo = "waynergy";
  };
  ref = "master";
}
