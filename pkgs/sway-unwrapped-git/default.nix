{ final, prev, gitOverride, ... }:

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
    mesonFlags =
      builtins.filter (x: builtins.substring 0 10 x != "-Dxwayland")
        prevAttrs.mesonFlags;
  };
}
