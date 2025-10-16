{
  final,
  final64 ? final,
  flakes,
  prev,
  gitOverride,
  nyxUtils,
  mesaTestAttrs ? final,
  ...
}:

let
  inherit (final.stdenv) is32bit;

  libdisplay-info_latest =
    if final.libdisplay-info.version == "0.2.0" then
      final.libdisplay-info.overrideAttrs (_prevAttrs: rec {
        version = "0.3.0";

        src = final.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "emersion";
          repo = "libdisplay-info";
          rev = version;
          sha256 = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
        };
      })
    else
      throw "Newer libdisplay-info in Nixpkgs";
in
gitOverride (current: {
  newInputs =
    if final.stdenv.isLinux then
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

  versionNyxPath = "pkgs/mesa-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "chaotic-cx";
    repo = "mesa-mirror";
  };
  withUpdateScript = !is32bit;

  # Matching the drvName length to use with replaceRuntime
  version = builtins.substring 0 (builtins.stringLength prev.mesa.version) current.rev;

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ [ libdisplay-info_latest ];

    patches = nyxUtils.removeByBaseName "gallivm-llvm-21.patch" prevAttrs.patches;

    mesonFlags = builtins.map (builtins.replaceStrings [ "imagination-experimental" ] [ "imagination-experimental" ]) prevAttrs.mesonFlags;

    # test and accessible information
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix {
        inherit (flakes) nixpkgs;
        chaotic = flakes.self;
      } mesaTestAttrs;
    };
  };
})
