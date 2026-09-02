{
  final,
  final64 ? final,
  prev,
  gitOverride,
  ...
}:

let
  inherit (final.stdenv.hostPlatform) is32bit;

  packageCache = final64.callPackage ./package-cache-dir.nix { };

  venus-protocol = final64.fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "virgl";
    repo = "venus-protocol";
    rev = "v1.1.1";
    hash = "sha256-VHn2UVpDB3UiJItFMh3/yndztIKZvHClVZDlTHztW7g=";
  };
in
gitOverride (current: {
  newInputs =
    if final.stdenv.hostPlatform.isLinux then
      {
        wayland-protocols = final64.wayland-protocols_git;
        vulkanLayers = prev.mesa.vulkanLayers ++ [
          "anti-lag"
        ];
      }
      // (
        if is32bit then
          with final64;
          {
            libdrm = libdrm32_git;
          }
        else
          with final;
          {
            libdrm = libdrm_git;
            galliumDrivers =
              # "rocket" is broken for 32bit
              [ "all" ];
          }
      )
    else
      { };

  nyxKey = if is32bit then "mesa32_git" else "mesa_git";
  prev = prev.mesa;

  manifestPath = "pkgs/mesa-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "chaotic-cx";
    repo = "mesa-mirror";
  };
  withUpdateScript = !is32bit;

  # Matching the drvName length to use with replaceRuntime
  version = builtins.substring 0 (builtins.stringLength prev.mesa.version) current.rev;

  postOverride = prevAttrs: {
    postUnpack = (prevAttrs.postUnpack or "") + ''
      rm source/subprojects/venus-protocol.wrap
      ln -s ${venus-protocol} source/subprojects/venus-protocol
    '';
    postPatch = (prevAttrs.postPatch or "") + ''
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I$PWD/include -Wno-error=format"
    '';
    env = (prevAttrs.env or { }) // {
      MESON_PACKAGE_CACHE_DIR = packageCache;
    };
  };
})
