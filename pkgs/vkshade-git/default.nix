{ final, prev, gitOverride, vkshade32_git, ... }:

gitOverride {
  newInputs = { vkbasalt32 = vkshade32_git; };
  nyxKey = if final.stdenv.is32bit then "vkshade32_git" else "vkshade_git";
  versionNyxPath = "pkgs/vkshade-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.vkbasalt;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "ralgar";
      repo = "vkShade";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "main"; };
  withUpdateScript = !final.stdenv.is32bit;

  postOverrides = [
    (prevAttrs: {
      pname = "vkshade";
      mesonFlags = builtins.map (builtins.replaceStrings [ "basalt" ] [ "shade" ]) prevAttrs.mesonFlags;
      postInstall = builtins.replaceStrings [ "Basalt" ] [ "Shade" ] prevAttrs.postInstall;
      postFixup = builtins.replaceStrings [ "Basalt" "BASALT" ] [ "Shade" "SHADE" ] prevAttrs.postFixup;
      meta = prevAttrs.meta // {
        homepage = "https://github.com/ralgar/vkShade";
        maintainers = with final.lib.maintainers; [ pedrohlc ];
      };
    })
  ];
}
