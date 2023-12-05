{ enableXWayland ? true
, final
, prev
, gitOverride
, ...
}:

gitOverride {
  newInputs = with final; {
    inherit enableXWayland;
    libdrm = libdrm_git;
    wayland = wayland_git;
    wayland-protocols = wayland-protocols_git;
    wayland-scanner = wayland-scanner_git;
  };

  nyxKey = "wlroots_git";
  prev = prev.wlroots_0_16;

  versionNyxPath = "pkgs/wlroots-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "wlroots";
    repo = "wlroots";
  };
  ref = "master";

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ (with final; [ hwdata libdisplay-info ]);
    postPatch = "";
  };
}
