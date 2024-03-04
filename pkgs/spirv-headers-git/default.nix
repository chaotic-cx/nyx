{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "spirv-headers_git";
  prev = prev.spirv-headers;

  versionNyxPath = "pkgs/spirv-headers-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
  };
}
