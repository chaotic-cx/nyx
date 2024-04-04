{ fetchFromGitHub }:

rec {
  version = "unstable-20240403-e19bc1b62";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "7d335fa1970e9a4a3a8da2dadde9762556eafe87";
    hash = "sha256-dZR0lgODeK3A5kDi0T2jXeFZFyZMedGzvxlhiNryX2A=";
    fetchSubmodules = true;
  };

}
