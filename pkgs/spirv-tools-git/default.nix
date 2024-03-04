{ final, prev, gitOverride, ... }:

gitOverride {
  newInputs = with final; {
    spirv-headers = spirv-headers_git;
  };

  nyxKey = "spirv-tools_git";
  prev = prev.spirv-tools;

  versionNyxPath = "pkgs/spirv-tools-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "KhronosGroup";
    repo = "SPIRV-Tools";
  };
}
