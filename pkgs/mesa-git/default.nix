{
  final,
  final64 ? final,
  prev,
  gitOverride,
  nyxUtils,
  ...
}:

let
  inherit (final.stdenv) is32bit;
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
    buildInputs = prevAttrs.buildInputs ++ [ final.libdisplay-info ];

    patches = nyxUtils.removeByBaseNames [
      "gallivm-llvm-21.patch"
      "musl.patch"
    ] (prevAttrs.patches or [ ]);

    postPatch = (prevAttrs.postPatch or "") + ''
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I$PWD/include -Wno-error=format"
    '';

    mesonFlags = map (builtins.replaceStrings
      [ "imagination-experimental" ]
      [ "imagination" ]
    ) prevAttrs.mesonFlags;
  };
})
