{ final, prev, gitOverride, ... }:

let
  src = {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "kcoreaddons";
  };
in
gitOverride {
  nyxKey = "kf6coreaddons_git";
  versionNyxPath = "pkgs/kf6coreaddons-git/version.json";
  versionLocalPath = ./version.json;
  prev = final.qt6.callPackage ./default.nix {
    extra-cmake-modules = final.extra-cmake-modules_git;
  };
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (src // finalArgs);
  fetchLatestRev = _src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { inherit src; ref = "master"; };
}
