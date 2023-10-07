{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "swaylock-plugin_git";
  prev = prev.swaylock;

  versionNyxPath = "pkgs/swaylock-plugin-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "mstoeckl";
    repo = "swaylock-plugin";
  };
}
