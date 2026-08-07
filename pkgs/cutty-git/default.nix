{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "cutty_git";
  prev = prev.alacritty;

  manifestPath = "pkgs/cutty-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "gold-silver-copper";
    repo = "cutty";
  };

  postOverride = prevAttrs: {
    pname = "cutty";

    doInstallCheck = false;

    postPatch = builtins.replaceStrings [ "alacritty" ] [ "cutty" ] prevAttrs.postPatch;
    postInstall =
      builtins.replaceStrings
        [
          "logo/compat/alacritty-term.svg"
          "hicolor/scalable"
          "alacritty"
          "Alacritty"
        ]
        [
          "logo/cutty-term.png"
          "hicolor/512x512"
          "cutty"
          "CuTTY"
        ]
        prevAttrs.postInstall;

    meta = prevAttrs.meta // {
      mainProgram = "cutty";
      maintainers = [ final.lib.maintainers.pedrohlc ];
      homepage = "https://github.com/gold-silver-copper/CuTTY";
      changelog = "https://github.com/gold-silver-copper/CuTTY/releases";
    };
  };
}
