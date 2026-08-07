{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "ananicy-rules-cachyos";
  prev = prev.ananicy-rules-cachyos;

  manifestPath = "pkgs/ananicy-cpp-rules/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "CachyOS";
    repo = "ananicy-rules";
  };
  ref = "master";
}
