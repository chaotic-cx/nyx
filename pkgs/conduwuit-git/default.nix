{ final, prev, gitOverride, conduwuitPins, ... }:
gitOverride (current: {
  nyxKey = "conduwuit_git";
  prev = prev.conduwuit;

  versionNyxPath = "pkgs/conduwuit-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "girlbossceo";
    repo = "conduwuit";
  };

  postOverride = prevAttrs: {
    cargoDeps = final.fetchCargoVendor {
        inherit (prevAttrs) src postUnpack;
        name = "conduwuit-deps";
        hash = current.cargoHash;
    };
  };
})
