{
  prev,
  gitOverride,
  rustPlatform_latest,
  ...
}:

gitOverride (current: {
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

  preOverride = prevAttrs: {
    postPatch = builtins.replaceStrings [ prevAttrs.version ] [ "*" ] prevAttrs.postPatch;
  };

  postOverride = prevAttrs: {
    env = prevAttrs.env // {
      RELEASE_VERSION = "";
      ZED_COMMIT_SHA = current.rev;
    };
    installPhase =
      builtins.replaceStrings [ "zed-remote-server-stable-$version" ] [ "zed-remote-server-dev-build" ]
        (
          builtins.replaceStrings [ "dev.zed.Zed.desktop" ] [ "dev.zed.Zed-Dev.desktop" ]
            prevAttrs.installPhase
        );
    patches = [ ./0002-use-patched-reqwest.patch ];
    # Nothing wrong on it, just saving compilation time for me!
    dontCheck = true;
    doInstallCheck = false;
  };

  buildCargoDepsWithPatches = finalDrv: finalDrv.patches;
})
