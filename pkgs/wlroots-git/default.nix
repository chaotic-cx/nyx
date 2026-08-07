{
  enableXWayland ? true,
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  newInputs = with final; {
    inherit enableXWayland;
    wayland = wayland_git;
    wayland-protocols = wayland-protocols_git;
    wayland-scanner = wayland-scanner_git;
  };

  nyxKey = "wlroots_git";
  prev = prev.wlroots;

  manifestPath = "pkgs/wlroots-git/manifest.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "wlroots";
    repo = "wlroots";
  };
  ref = "master";

  postOverride = _prevAttrs: {
    patches = [ ];
  };
}
