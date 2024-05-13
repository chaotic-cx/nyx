{ enableXWayland ? true
, final
, prev
, gitOverride
, nyxUtils
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
    patches = nyxUtils.removeByURL
      "https://gitlab.freedesktop.org/wlroots/wlroots/-/commit/fe53ec693789afb44c899cad8c2df70c8f9f9023.patch"
      prevAttrs.patches;
    buildInputs = [ final.lcms ] ++ prevAttrs.buildInputs;
  };
}
