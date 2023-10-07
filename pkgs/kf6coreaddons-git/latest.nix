{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "kf6coreaddons_git";
  prev = final.qt6.callPackage ./default.nix {
    extra-cmake-modules = final.extra-cmake-modules_git;
  };

  versionNyxPath = "pkgs/kf6coreaddons-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "kcoreaddons";
  };
  ref = "master";
}
