{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "libbpf_git";
  prev = prev.libbpf;

  versionNyxPath = "pkgs/libbpf-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "libbpf";
    repo = "libbpf";
  };
  ref = "master";
}
