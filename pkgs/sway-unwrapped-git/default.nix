{ final, prev, gitOverride, nyxUtils, ... }:

gitOverride {
  newInputs = with final; {
    libdrm = libdrm_git;
    wlroots = wlroots_git;
    wayland = wayland_git;
    wayland-protocols = wayland-protocols_git;
    wayland-scanner = wayland-scanner_git;
  };

  nyxKey = "sway-unwrapped_git";
  prev = prev.sway-unwrapped;

  versionNyxPath = "pkgs/sway-unwrapped-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "swaywm";
    repo = "sway";
  };
  ref = "master";

  postOverride = prevAttrs: {
    patches =
      nyxUtils.removeByURL
        "https://github.com/swaywm/sway/commit/dee032d0a0ecd958c902b88302dc59703d703c7f.diff"
        prevAttrs.patches;
  };
}
