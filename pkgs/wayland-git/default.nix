{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; { wayland-scanner = wayland-scanner_git; };

  nyxKey = "wayland_git";
  prev = prev.wayland;

  versionNyxPath = "pkgs/wayland-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "wayland";
    repo = "wayland";
  };

  postOverride = prevAttrs: {
    patches = [ ];
  };
}
