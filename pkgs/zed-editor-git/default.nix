{ prev, gitOverride, rustPlatform_latest, ... }:

gitOverride {
  nyxKey = "zed-editor_git";
  prev = prev.zed-editor;

  newInputs = {
    rustPlatform = rustPlatform_latest;
  };

  versionNyxPath = "pkgs/zed-editor-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "zed-industries";
    repo = "zed";
    fetchSubmodules = true;
  };
  ref = "main";

  postOverride = _prevAttrs: {
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    doInstallCheck = false;
  };
}
