{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; { glib = glib_git; };
  nyxKey = "tg-owt_git";
  versionNyxPath = "pkgs/tg-owt-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.telegram-desktop.tg_owt;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "desktop-app";
      repo = "tg_owt";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
  hasSubmodules = true;
}
