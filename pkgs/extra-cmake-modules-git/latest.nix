{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "extra-cmake-modules_git";
  prev = final.qt6.callPackage ./default.nix { };

  versionNyxPath = "pkgs/extra-cmake-modules-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "extra-cmake-modules";
  };
  ref = "master";
}
