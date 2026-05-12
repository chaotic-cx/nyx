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

        cleanedPostPatch =
          builtins.replaceStrings
            [
              ''substituteInPlace src/reshade_effect_manager.cpp --replace-fail "@out@" "$out"''
            ]
            [
              ""
            ]
            prevAttrs.postPatch;
      in
      cleanedPostPatch
      + ''
        substituteInPlace layer/VkLayer_FROG_gamescope_wsi.cpp \
          --replace-fail 'WSI] Surface' 'WSI ${shortRev}] Surface'

        substituteInPlace src/meson.build \
          --replace-fail "'git', 'describe', '--always', '--tags', '--dirty=+'" \
                         "'echo', '${current.rev}'"

        # Disable broken tests subdir in current upstream snapshot
        substituteInPlace meson.build \
          --replace-fail "subdir('tests')" ""

        patchShebangs default_extras_install.sh
      '';

    # gamescope master already includes these patches
    # filter them to keep git builds working
    patches = builtins.filter (
      p:
      let
        lib = prev.lib;
        path = toString p;
      in
      !(lib.hasInfix "shaders-path" path)
      && !(lib.hasInfix "54e844748029d4874e14d0c086d50092c04c8899" path)
    ) prevAttrs.patches;

    # Skip unstable test suite (Catch2 not available / tests may be incomplete in git master)
    doCheck = false;
  };
})
