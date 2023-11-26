{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "fractal_git";
  prev = prev.fractal-next;

  versionNyxPath = "pkgs/fractal-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "fractal";
  };
  ref = "main";

  withCargoDeps = lockFile: final.rustPlatform.importCargoLock {
    inherit lockFile;
    outputHashes = {
      "mas-http-0.5.0-rc.2" = "sha256-XH+I5URcbkSY4NDwfOFhIjb+/swuGz6n9hKufziPgoY=";
      "matrix-sdk-0.6.2" = "sha256-X+4077rlaE8zjXHXPUfiYwa/+Bg0KTFrcsAg7yCz4ug=";
    };
  };
}
