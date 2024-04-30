{ fetchFromGitHub }:

rec {
  version = "unstable-20240429-b1bb2a5c5";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "b1bb2a5c5f76d45d494480d90aacd2fc18535cd7";
    hash = "sha256-CidStlelh+QFkNmvleg/zJf6FIeePL2HPPIPRbyKfpw=";
    fetchSubmodules = true;
  };
}
