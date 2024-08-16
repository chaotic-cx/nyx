{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "lix_git";
  prev = prev.lix;

  versionNyxPath = "pkgs/lix-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "lix-project";
    repo = "lix";
  };
  ref = "main";
}
