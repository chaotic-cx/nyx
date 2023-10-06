{ final, prev, gitOverride, ... }:

let
  src = {
    domain = "gitlab.freedesktop.org";
    owner = "wayland";
    repo = "wayland";
  };
in
gitOverride {
  newInputs = with final; { wayland-scanner = wayland-scanner_git; };
  nyxKey = "wayland_git";
  versionNyxPath = "pkgs/wayland-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.wayland;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (src // finalArgs);
  fetchLatestRev = _src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { inherit src; ref = "main"; };

  postOverrides = [
    (prevAttrs: {
      patches = [ ];
    })
  ];
}
