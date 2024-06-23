{ final, prev, gitOverride, nyxUtils, isWSI ? false, ... }:

gitOverride (current: {
  nyxKey = if isWSI then "gamescope-wsi_git" else "gamescope_git";
  prev = if isWSI then prev.gamescope-wsi else prev.gamescope;

  versionNyxPath = "pkgs/gamescope-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "gamescope";
    fetchSubmodules = true;
  };
  ref = "master";
  withUpdateScript = !isWSI;

  postOverride = prevAttrs: {
    # Taints commits in logs for debugging purposes
    postPatch =
      let shortRev = nyxUtils.shorter current.rev; in
      prevAttrs.postPatch + ''
        substituteInPlace layer/VkLayer_FROG_gamescope_wsi.cpp \
          --replace-fail 'WSI] Surface' 'WSI ${shortRev}] Surface'
        substituteInPlace src/main.cpp \
          --replace-fail 'usage:' 'rev: ${shortRev}\nusage:'
      '';
  };
})
