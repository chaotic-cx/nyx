{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "openvr_git";
  prev = prev.openvr;

  versionNyxPath = "pkgs/openvr-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "openvr";
    fetchSubmodules = true;
  };
  ref = "master";
}
