{ final, prev, gitOverride, niriPins, ... }:

gitOverride {
  nyxKey = "niri_git";
  prev = prev.niri;

  versionNyxPath = "pkgs/niri-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "YaLTeR";
    repo = "niri";
  };

  withCargoDeps = lockFile: final.rustPlatform.importCargoLock {
    inherit lockFile;
    outputHashes = niriPins;
  };
}
