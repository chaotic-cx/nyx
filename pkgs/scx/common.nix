{ fetchFromGitHub }:

rec {
  version = "0.1.10";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-zeKmBDpxLRSiVPpcgsfED/xceVB2BcndbFvf7Ug6Bfk=";
    fetchSubmodules = true;
  };
}
