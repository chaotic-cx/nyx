{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "gamescope_git";
  prev = prev.gamescope;

  versionNyxPath = "pkgs/gamescope-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "gamescope";
    fetchSubmodules = true;
  };
  ref = "master";

  postOverride = _prevAttrs: {
    # erase wlroots replacement since we're fetching submodules.
    postUnpack = "";
  };
}
