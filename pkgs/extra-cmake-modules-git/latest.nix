{ final, prev, gitOverride, ... }:

let
  src = {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "extra-cmake-modules";
  };
in
gitOverride {
  nyxKey = "extra-cmake-modules_git";
  versionNyxPath = "pkgs/extra-cmake-modules-git/version.json";
  versionLocalPath = ./version.json;
  prev = final.qt6.callPackage ./default.nix { };
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (src // finalArgs);
  fetchLatestRev = _src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { inherit src; ref = "master"; };
}
