{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "openmohaa_git";
  prev = final.openmohaa;

  versionNyxPath = "pkgs/openmohaa-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "openmoh";
    repo = "openmohaa";
  };
}
