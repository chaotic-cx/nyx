{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; { vkbasalt32 = vkshade32_git; };

  nyxKey = if final.stdenv.is32bit then "vkshade32_git" else "vkshade_git";
  prev = prev.vkbasalt;

  versionNyxPath = "pkgs/vkshade-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ralgar";
    repo = "vkShade";
  };
  withUpdateScript = !final.stdenv.is32bit;

  postOverride = prevAttrs: {
    pname = "vkshade";
    mesonFlags = builtins.map (builtins.replaceStrings [ "basalt" ] [ "shade" ]) prevAttrs.mesonFlags;
    postInstall = builtins.replaceStrings [ "Basalt" ] [ "Shade" ] prevAttrs.postInstall;
    postFixup = builtins.replaceStrings [ "Basalt" "BASALT" ] [ "Shade" "SHADE" ] prevAttrs.postFixup;
    meta = prevAttrs.meta // {
      homepage = "https://github.com/ralgar/vkShade";
      maintainers = with final.lib.maintainers; [ pedrohlc ];
    };
  };
}
