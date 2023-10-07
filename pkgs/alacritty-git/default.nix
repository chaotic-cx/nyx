{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "alacritty_git";
  prev = prev.alacritty;

  versionNyxPath = "pkgs/alacritty-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "alacritty";
    repo = "alacritty";
  };
  ref = "master";

  postOverride = prevAttrs: {
    postInstall =
      builtins.replaceStrings
        [ "extra/alacritty.man" "extra/alacritty-msg.man" "install -Dm 644 alacritty.yml $out/share/doc/alacritty.yml" ]
        [ "extra/alacritty.*" "extra/alacritty-msg.*" "" ]
        prevAttrs.postInstall;
  };
}
