{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "extra-cmake-modules_git";
  prev = prev.kdePackages.extra-cmake-modules;

  versionNyxPath = "pkgs/extra-cmake-modules-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "extra-cmake-modules";
  };
  ref = "master";
}
