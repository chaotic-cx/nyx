{ enableXWayland ? true
, final
, prev
, gitOverride
, ...
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

  versionNyxPath = "pkgs/wlroots-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "wlroots";
    repo = "wlroots";
  };
  ref = "master";

  postOverride = prevAttrs: {
    buildInputs = (with final; [ hwdata libdrm_git libdisplay-info ]) ++ prevAttrs.buildInputs;
    postPatch = "";
  };
}
