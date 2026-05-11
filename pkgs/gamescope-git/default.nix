{
  prev,
  gitOverride,
  nyxUtils,
  isWSI ? false,
  ...
}:

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
    postPatch =
      let
        shortRev = nyxUtils.shorter current.rev;
      in
      prevAttrs.postPatch
      + ''
        substituteInPlace layer/VkLayer_FROG_gamescope_wsi.cpp \
          --replace-fail 'WSI] Surface' 'WSI ${shortRev}] Surface'
        substituteInPlace src/meson.build \
          --replace-fail "'git', 'describe', '--always', '--tags', '--dirty=+'" "'echo', '${current.rev}'"

        patchShebangs default_extras_install.sh
      '';

    # gamescope master already includes this wlroots patch
    # filter it to keep git builds working
    patches =
      let
        obsoletePatch = "54e844748029d4874e14d0c086d50092c04c8899";
      in
      builtins.filter (p: !(prev.lib.hasInfix obsoletePatch (builtins.toString p))) prevAttrs.patches;
  };
})
