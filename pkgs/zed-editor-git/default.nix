{ final, prev, gitOverride, ... }:

gitOverride (current: {
  nyxKey = "zed-editor_git";
  prev = prev.zed-editor;

  versionNyxPath = "pkgs/zed-editor-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "zed-industries";
    repo = "zed";
    fetchSubmodules = true;
  };
  ref = "main";

  preOverride = prevAttrs: {
    postPatch = builtins.replaceStrings [ prevAttrs.version ] [ "*" ] prevAttrs.postPatch;
  };

  postOverride = prevAttrs: {
    env = (builtins.removeAttrs prevAttrs.env [ "RELEASE_VERSION" ]) // {
      ZED_COMMIT_SHA = current.rev;
    };
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    doInstallCheck = false;
  };
})
