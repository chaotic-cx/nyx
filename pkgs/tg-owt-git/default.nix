{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "tg-owt_git";
  prev = prev.telegram-desktop.tg_owt;

  versionNyxPath = "pkgs/tg-owt-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "desktop-app";
    repo = "tg_owt";
    fetchSubmodules = true;
  };
  ref = "master";
}
