{ final, prev, gitOverride, nyxUtils, ... }:

gitOverride {
  newInputs = { wlroots = final.wlroots_git; };
  nyxKey = "sway-unwrapped_git";
  versionNyxPath = "pkgs/sway-unwrapped-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.sway-unwrapped;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "swaywm";
      repo = "sway";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };

  postOverrides = [
    (prevAttrs: {
      patches =
        nyxUtils.removeByURL
          "https://github.com/swaywm/sway/commit/dee032d0a0ecd958c902b88302dc59703d703c7f.diff"
          prevAttrs.patches;
    })
  ];
}
