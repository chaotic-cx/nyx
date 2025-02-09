{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "sdl_git";
  prev = prev.sdl3;

  versionNyxPath = "pkgs/sdl-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "libsdl-org";
    repo = "SDL";
  };
  ref = "main";
}
