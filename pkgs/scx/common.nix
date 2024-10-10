{ fetchFromGitHub }:

rec {
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-nb2bzEanPPWTUhMmGw/8/bwOkdgNmwoZX2lMFq5Av5Q=";
    fetchSubmodules = true;
  };
}
