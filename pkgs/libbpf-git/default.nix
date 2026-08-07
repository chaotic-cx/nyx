{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "libbpf_git";
  prev = prev.libbpf;

  manifestPath = "pkgs/libbpf-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "libbpf";
    repo = "libbpf";
  };
  ref = "master";

  postOverride = _prevAttrs: {
    patches = [ ];
  };
}
