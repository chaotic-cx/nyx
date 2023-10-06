{ final, prev, gitOverride, ... }:

let
  src = {
    domain = "gitlab.freedesktop.org";
    owner = "wayland";
    repo = "wayland-protocols";
  };
in
gitOverride {
  nyxKey = "wayland-protocols_git";
  versionNyxPath = "pkgs/wayland-protocols-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.wayland-protocols;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (src // finalArgs);
  fetchLatestRev = _src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { inherit src; ref = "main"; };
}
