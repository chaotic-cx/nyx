{ final, prev, gitOverride, nyxUtils, isWSI ? false, ... }:

gitOverride (current: {
  newInputs = with final; {
    openvr = openvr_git;
    wlroots = wlroots_git.overrideAttrs (_wlrPrev: {
      src = fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "wlroots";
        repo = "wlroots";
        rev = "a5c9826e6d7d8b504b07d1c02425e6f62b020791";
        hash = "sha256-G7CvsSRryNCoknWhfoZvkf33967xI51WkemA6ms3vo4=";
      };
    });
  };

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
    buildInputs = with final; [ seatd xwayland libdecor ] ++ (with xorg; [ xcbutilwm xcbutilerrors ]) ++ prevAttrs.buildInputs;

    patches = with final; prevAttrs.patches ++ [ ./6.8-color.patch ];

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
