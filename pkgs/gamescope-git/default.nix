{ final, prev, gitOverride, isWSI ? false, ... }:

gitOverride {
  newInputs = with final; {
    openvr = openvr_git;
    wlroots = wlroots_git;
    wayland = wayland_git;
    wayland-protocols = wayland-protocols_git;
    inherit (vulkanPackages_latest) vulkan-loader vulkan-headers glslang;
  };

  nyxKey = if isWSI then "gamescope-wsi_git" else "gamescope_git";
  prev = if isWSI then prev.gamescope-wsi else prev.gamescope;

  versionNyxPath = "pkgs/gamescope-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "gamescope";
    fetchSubmodules = true;
  };
  ref = "master";
  withUpdateScript = !isWSI;

  postOverride = prevAttrs: {
    buildInputs = with final; [ seatd libavif xwayland ] ++ (with xorg; [ xcbutilwm xcbutilerrors ]) ++ prevAttrs.buildInputs;

    # erase wlroots replacement since we're fetching submodules.
    postUnpack = "";
  };
}
