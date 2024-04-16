{ fetchFromGitHub }:

rec {
  version = "unstable-20240415-b9d57e85b";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "b9d57e85b50d5a7168854a54eb36506388f3991a";
    hash = "sha256-oDyH1Jq4UaHSAi3X5WSi75ObllhrUdMTJGmonpeaJnY=";
    fetchSubmodules = true;
  };

}
