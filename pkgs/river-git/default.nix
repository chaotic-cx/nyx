{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; {
    zig_0_11 = zig;
    wlroots_0_16 = wlroots_0_17;
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
