{ final, prev, gitOverride, nyxUtils, ... }:

let
  inherit (final.stdenv) is32bit;
in
gitOverride {
  newInputs = with final; { mangohud32 = mangohud32_git; };
  nyxKey = if is32bit then "mangohud32_git" else "mangohud_git";
  prev = prev.mangohud;

  versionNyxPath = "pkgs/mangohud-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "flightlessmango";
    repo = "MangoHud";
  };
  ref = "master";
  withUpdateScript = !final.stdenv.is32bit;

  postOverride = prevAttrs: {
    doCheck = false;
    buildInputs = with final; [ SDL2 ] ++ prevAttrs.buildInputs;
    mesonFlags = nyxUtils.removeByPrefix "-Dmangoapp_layer=" prevAttrs.mesonFlags;
    postInstall = if is32bit then prevAttrs.postInstall else prevAttrs.postInstall + ''
      rm "$out/share/vulkan/implicit_layer.d/libMangoApp.x86.json"
    '';
    patches =
      [
        ./preload-nix-workaround.patch
        (with final; substituteAll {
          src = ./hardcode-dependencies.patch;

          path = lib.makeBinPath [
            coreutils
            curl
            gnugrep
            gnused
            mesa-demos
            xdg-utils
          ];

          libdbus = dbus.lib;
          inherit hwdata;
        })
      ];
  };
}
