{ final, prev, gitOverride, nyxUtils, ... }:

gitOverride {
  newInputs = with final; {
    wlroots = wlroots_git;
    wayland = wayland_git;
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
    buildInputs = with final.xorg; [ libXcursor xcbutilwm xcbutilerrors final.libavif ] ++ prevAttrs.buildInputs;

    patches =
      (nyxUtils.removeByBaseName "use-pkgconfig.patch" prevAttrs.patches)
      ++ [ ./use-pkgconfig.patch ];

    postInstall = prevAttrs.postInstall + ''
      rm -r $out/include $lib/lib/pkgconfig $lib/lib/libwlroots.a
    '';

    # erase wlroots replacement since we're fetching submodules.
    postUnpack = "";
  };
}
