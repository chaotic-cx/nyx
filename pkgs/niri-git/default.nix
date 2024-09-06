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

  withCargoDeps = final.rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = niriPins;
  };

  postOverride = prevAttrs: {
    buildInputs = [ final.libdisplay-info ] ++ prevAttrs.buildInputs;
  };
}
