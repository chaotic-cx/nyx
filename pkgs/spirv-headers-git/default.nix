{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "spirv-headers_git";
  prev = prev.spirv-headers;

  manifestPath = "pkgs/spirv-headers-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
  };

  postOverride = _prevAttrs: {
    patches = [ ];
  };
}
