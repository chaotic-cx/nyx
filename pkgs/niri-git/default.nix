{
  final,
  prev,
  gitOverride,
  nyxUtils,
  ...
}:

gitOverride {
  nyxKey = "niri_git";
  prev = prev.niri;

  versionNyxPath = "pkgs/niri-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "YaLTeR";
    repo = "niri";
  };

  postOverride = prevAttrs: {
    buildInputs = [ final.libdisplay-info ] ++ prevAttrs.buildInputs;
    patches = nyxUtils.removeByURL "https://github.com/YaLTeR/niri/commit/1951d2a9f262196a706f2645efb18dac3c4d6839.patch" prevAttrs.patches;
    nativeInstallCheckInputs = [ ];
  };
}
