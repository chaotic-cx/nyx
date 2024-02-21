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
    buildInputs = prevAttrs.buildInputs ++ [ final.SDL2 ];
    patches =
      [
        ./preload-nix-workaround.patch
        (with final; substituteAll {
          src = ./hardcode-dependencies.patch;

          path = lib.makeBinPath [
            coreutils
            curl
            glxinfo
            gnugrep
            gnused
            xdg-utils
          ];

          libdbus = dbus.lib;
          inherit hwdata;
        })
      ];
  };
}
