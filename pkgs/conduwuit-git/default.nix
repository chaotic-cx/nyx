{ final, prev, gitOverride, nyxUtils, rustPlatform_latest, ... }:
gitOverride (current: {
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
    meta = prevAttrs.meta // { mainProgram = "conduwuit"; };
    # watermark
    env = prevAttrs.env // {
      CONDUWUIT_VERSION_EXTRA = "${nyxUtils.shorter current.rev}+nyx";
    };
    # We need blurhashing, sentry requires opt-in during runtime (set `sentry = true` in your config)
    buildNoDefaultFeatures = false;
    cargoBuildNoDefaultFeatures = false;
    cargoCheckNoDefaultFeatures = false;
    buildFeatures = [ "blurhashing" "sentry_telemetry" ];
    cargoBuildFeatures = [ "blurhashing" "sentry_telemetry" ];
    cargoCheckFeatures = [ "blurhashing" "sentry_telemetry" ];
    # autoPatchelfHook & buildInputs is needed when using Fenix
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.autoPatchelfHook ];
    buildInputs = prevAttrs.buildInputs ++ [ final.rocksdb ] ++ (if final.stdenv.isLinux then [ final.libgcc.libgcc ] else [ ]);
  };
})
