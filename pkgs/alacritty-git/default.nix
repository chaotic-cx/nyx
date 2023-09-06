{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "alacritty_git";
  versionNyxPath = "pkgs/alacritty-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.alacritty;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "alacritty";
      repo = "alacritty";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
  postOverrides = [
    (prevAttrs: {
      postInstall =
        builtins.replaceStrings
          [ "extra/alacritty.man" "extra/alacritty-msg.man" "install -Dm 644 alacritty.yml $out/share/doc/alacritty.yml" ]
          [ "extra/alacritty.*" "extra/alacritty-msg.*" "" ]
          prevAttrs.postInstall;
    })
  ];
}
