{ final
, final64 ? final
, flakes
, prev
, gitOverride
, nyxUtils
, gbmDriver ? true
, mesaTestAttrs ? final
, ...
}:

let
  inherit (final.stdenv) is32bit;
in
gitOverride (current: {
  newInputs =
    {
      wayland-protocols = final64.wayland-protocols_git;
      galliumDrivers = [ "all" ];
    } // (if is32bit then with final64; {
      libdrm = libdrm32_git;
    } else with final; {
      libdrm = libdrm_git;
    });

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
    patches = (nyxUtils.removeByBaseNames [ "opencl.patch" ] prevAttrs.patches) ++ [ ./opencl.patch ];

    # test and accessible information
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix
        {
          inherit (flakes) nixpkgs;
          chaotic = flakes.self;
        }
        mesaTestAttrs;
    };
  };
})
