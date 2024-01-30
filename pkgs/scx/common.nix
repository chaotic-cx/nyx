{ fetchFromGitHub }:

rec {
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "v${version}";
    hash = "sha256-ZS62xSKgs5ifBsUQmH3b2CD3KpPAo5FM7Ha5nzbWviY=";
    fetchSubmodules = true;
  };

}
