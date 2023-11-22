{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; {
    wlroots = wlroots_git;
    wayland = wayland_git;
    wayland-scanner = wayland-scanner_git;
    wayland-protocols = wayland-protocols_git;
    inherit (vulkanPackages_latest) vulkan-loader vulkan-headers glslang;
  };

  nyxKey = "gamescope_git";
  prev = prev.gamescope;

  versionNyxPath = "pkgs/gamescope-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "gamescope";
    fetchSubmodules = true;
  };
  ref = "master";

  postOverride = prevAttrs: {
    # erase wlroots replacement since we're fetching submodules.
    postUnpack = "";
  };
}
