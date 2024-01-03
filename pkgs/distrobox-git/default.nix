{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "distrobox_git";
  prev = prev.alacritty;

  versionNyxPath = "pkgs/distrobox-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "89luca89";
    repo = "distrobox";
  };
  ref = "main";
 }
