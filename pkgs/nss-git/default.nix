{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nss_git";
  prev = prev.nss_latest;

  versionNyxPath = "pkgs/nss-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "nss-dev";
    repo = "nss";
  };
  ref = "master";
}
