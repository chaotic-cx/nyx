{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "owl-wlr_git";
  prev = final.callPackage ./package.nix { };

  versionNyxPath = "pkgs/owl-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "dqrk0jeste";
    repo = "owl";
    fetchSubmodules = true;
  };
}
