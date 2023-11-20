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
      ++ [ ./split-dev-programs.patch ];
  };
}
