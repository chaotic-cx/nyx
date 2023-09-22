{ prev, final, nyxUtils, gitOverride, ... }:

let
  srcMeta = {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "glib";
  };
in
gitOverride {
  nyxKey = "glib_git";
  versionNyxPath = "pkgs/glib-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.glib;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (srcMeta // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { src = src // srcMeta; ref = "main"; };
  hasSubmodules = true;

  postOverrides = [
    (prevAttrs: rec {
      patches =
        (nyxUtils.removeByBaseName "split-dev-programs.patch" prevAttrs.patches)
        ++ [
          (final.fetchpatch {
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/8f5cf46a9b75b934323971b8bc9dc571888164f0/pkgs/development/libraries/glib/split-dev-programs.patch";
            hash = "sha256-fPGXPBPMNdpwZn+VJMRTzDK2UX/0q09RAyigbIf2jq4=";
          })
        ];
    })
  ];
}
