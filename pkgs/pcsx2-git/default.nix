{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "pcsx2_git";
  prev = prev.pcsx2;

  newInputs = with final; {
    SDL2 = sdl3;
  };

  versionNyxPath = "pkgs/pcsx2-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "PCSX2";
    repo = "pcsx2";
  };
  ref = "master";

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ (with final; [
      plutovg
      plutosvg
    ]);
  };
}
