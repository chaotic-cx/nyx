{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "openvr_git";
  prev = prev.openvr;

  manifestPath = "pkgs/openvr-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "openvr";
    fetchSubmodules = true;
  };
  ref = "master";
}
