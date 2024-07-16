{ fetchFromGitHub }:

rec {
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-4uM69RJdRm75z595QIA/zJYl6b00HqT363vfoXIRqzY=";
    fetchSubmodules = true;
  };
}
