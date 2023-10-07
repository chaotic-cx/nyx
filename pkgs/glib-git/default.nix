{ prev, final, nyxUtils, gitOverride, ... }:

gitOverride {
  nyxKey = "glib_git";
  prev = prev.glib;

  versionNyxPath = "pkgs/glib-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "glib";
    fetchSubmodules = true;
  };

  postOverride = prevAttrs: {
    patches =
      (nyxUtils.removeByBaseName "split-dev-programs.patch" prevAttrs.patches)
      ++ [
        (final.fetchpatch {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/8f5cf46a9b75b934323971b8bc9dc571888164f0/pkgs/development/libraries/glib/split-dev-programs.patch";
          hash = "sha256-fPGXPBPMNdpwZn+VJMRTzDK2UX/0q09RAyigbIf2jq4=";
        })
      ];
  };
}
