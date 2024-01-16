{ fetchFromGitHub }:

rec {
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "v${version}";
    hash = "sha256-frPPzR9ejbqfKc8cRrkVYw595jo/l8k3F75ekQDPsmc=";
    fetchSubmodules = true;
  };

}
