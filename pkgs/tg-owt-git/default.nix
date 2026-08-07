{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "tg-owt_git";
  prev = prev.telegram-desktop.tg_owt;

  manifestPath = "pkgs/tg-owt-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "desktop-app";
    repo = "tg_owt";
    fetchSubmodules = true;
  };
  ref = "master";
}
