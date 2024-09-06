{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; { mangohud32 = mangohud32_git; };
  nyxKey = if final.stdenv.is32bit then "mangohud32_git" else "mangohud_git";
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
    buildInputs = with final; [ SDL2 libxkbcommon ] ++ prevAttrs.buildInputs;
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
