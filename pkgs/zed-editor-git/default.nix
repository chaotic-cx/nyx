{ prev, gitOverride, ... }:

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
    postPatch = (builtins.replaceStrings [ prevAttrs.version ] [ "*" ] prevAttrs.postPatch) + ''
      substituteInPlace script/generate-licenses \
        --replace-fail 'CARGO_ABOUT_VERSION="0.6"' 'CARGO_ABOUT_VERSION="0.7"'
    '';
  };

  postOverride = prevAttrs: {
    env = (builtins.removeAttrs prevAttrs.env [ "RELEASE_VERSION" ]) // {
      RELEASE_VERSION = "";
      ZED_COMMIT_SHA = current.rev;
    };
    installPhase = builtins.replaceStrings [ "zed-remote-server-stable-$version" ] [ "zed-remote-server-dev-build" ] prevAttrs.installPhase;
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    doInstallCheck = false;
  };
})
