{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; {
    wlroots = wlroots_git;
    wayland = wayland_git;
    wayland-scanner = wayland-scanner_git;
    wayland-protocols = wayland-protocols_git;
    vulkan-loader = vulkanPackages_latest.vulkan-loader;
    vulkan-headers = vulkanPackages_latest.vulkan-headers;
    glslang = vulkanPackages_latest.glslang;
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
    patches = prevAttrs.patches ++ [
      (final.fetchpatch2 {
        url = "https://github.com/ValveSoftware/gamescope/commit/d4ca57e1f4afe0b0798bf71406b1430a915a7bb3.patch";
        hash = "sha256-XG8114bHGuhW7WmXufPMVf2yFKml8A4uTP3ucvIiH2I=";
      })
    ];

    # erase wlroots replacement since we're fetching submodules.
    postUnpack = "";
  };
}
