{
  gitOverride,
  prev,
  ...
}:
gitOverride (_current: {
  nyxKey = "bees_git";
  prev = prev.bees;
  versionNyxPath = "pkgs/bees-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "Zygo";
    repo = "bees";
  };
  ref = "master";
})
