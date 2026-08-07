{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "sdl_git";
  prev = prev.sdl3;

  manifestPath = "pkgs/sdl-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "libsdl-org";
    repo = "SDL";
  };

  postOverride = _prevAttrs: {
    doCheck = false;
  };
}
