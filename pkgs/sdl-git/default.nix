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

  postOverride = prev: {
    postPatch =
      builtins.replaceStrings
        [ "src/video/wayland/SDL_waylandmessagebox.c" ]
        [ "src/dialog/unix/SDL_zenitymessagebox.c" ]
        prev.postPatch;
  };
}
