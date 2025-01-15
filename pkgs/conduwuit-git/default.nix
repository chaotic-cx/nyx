{ final, prev, gitOverride, rustPlatform_latest, ... }:
gitOverride {
  nyxKey = "conduwuit_git";
  prev = prev.conduwuit;

  newInputs = {
    rustPlatform = rustPlatform_latest;
    # Needed when using Fenix
    enableJemalloc = false;
  };

  versionNyxPath = "pkgs/conduwuit-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "girlbossceo";
    repo = "conduwuit";
  };

  postOverride = prevAttrs: {
    # autoPatchelfHook & buildINputs is needed when using Fenix
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.autoPatchelfHook ];
    buildInputs = prevAttrs.buildInputs ++ [ final.rocksdb final.libgcc.libgcc ];
  };
}
