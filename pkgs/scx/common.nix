{ fetchFromGitHub }:

rec {
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "v${version}";
    hash = "sha256-c51OAcH6J5m0/Z/+8WU6RQGY/13XnxbHwQY2YV7F6IY=";
    fetchSubmodules = true;
  };

}
