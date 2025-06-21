{
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "pcsx2_git";
  prev = prev.pcsx2;

  versionNyxPath = "pkgs/pcsx2-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "PCSX2";
    repo = "pcsx2";
  };
  ref = "master";
}
