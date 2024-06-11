{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "jujutsu_git";
  prev = prev.jujutsu;

  versionNyxPath = "pkgs/jujutsu-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "martinvonz";
    repo = "jj";
  };
}
