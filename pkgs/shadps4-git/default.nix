{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "shadps4_git";
  prev = prev.shadps4;

  versionNyxPath = "pkgs/shadps4-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "shadps4-emu";
    repo = "shadPS4";
    fetchSubmodules = true;
  };
}
