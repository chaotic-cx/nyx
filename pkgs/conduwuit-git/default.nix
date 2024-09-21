{ final, prev, rustPlatform_latest, gitOverride, conduwuitPins, ... }:
gitOverride {
  nyxKey = "conduwuit_git";
  prev = prev.conduwuit;

  newInputs = with final; {
    rustPlatform = rustPlatform_latest;
  };

  versionNyxPath = "pkgs/conduwuit-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "girlbossceo";
    repo = "conduwuit";
  };

  withCargoDeps = final.rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = conduwuitPins;
  };

  postOverride = prevAttrs: {
    # Adds the setup-hook
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.rust-jemalloc-sys-unprefixed ];
  };
}
