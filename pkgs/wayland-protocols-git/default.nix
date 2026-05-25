{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  newInputs = with final; {
    wayland-scanner = wayland-scanner_git;
  };

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
