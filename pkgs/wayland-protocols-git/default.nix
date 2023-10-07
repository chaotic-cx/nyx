{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "wayland-protocols_git";
  prev = prev.wayland-protocols;

  versionNyxPath = "pkgs/wayland-protocols-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "wayland";
    repo = "wayland-protocols";
  };
}
