{ final, prev, gitOverride, ... }:
gitOverride {
  nyxKey = "conduwuit_git";
  prev = prev.conduwuit;

  versionNyxPath = "pkgs/conduwuit-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "girlbossceo";
    repo = "conduwuit";
  };

  postOverride = prevAttrs: {
    meta = prevAttrs.meta // { mainProgram = "conduwuit"; };
  };
}
