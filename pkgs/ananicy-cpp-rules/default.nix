{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "ananicy-rules-cachyos";
  prev = prev.ananicy-rules-cachyos;

  versionNyxPath = "pkgs/ananicy-cpp-rules/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "CachyOS";
    repo = "ananicy-rules";
  };
  ref = "master";
}
