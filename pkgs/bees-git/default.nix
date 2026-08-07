{
  gitOverride,
  prev,
  ...
}:
gitOverride (_current: {
  nyxKey = "bees_git";
  prev = prev.bees;
  manifestPath = "pkgs/bees-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "Zygo";
    repo = "bees";
  };
  ref = "master";
})
