{ fetchFromGitHub }:

rec {
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-7oGuEPcVERuYVIohvqDV4jl2p3rNy6epD3QzcYt2QzI=";
    fetchSubmodules = true;
  };
}
