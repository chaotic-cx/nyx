{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; {
    wlroots_0_16 = wlroots;
    zig_0_10 = zig;
  };

  nyxKey = "river_git";
  prev = prev.river;

  versionNyxPath = "pkgs/river-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "riverwm";
    repo = "river";
    fetchSubmodules = true;
  };
  ref = "master";
}
