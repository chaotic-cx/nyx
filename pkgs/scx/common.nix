{ fetchFromGitHub }:

rec {
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-VSpuEYgOIE8sxcUL+D8os5TF6JVYFzWXj23Qe5gxc3Y=";
    fetchSubmodules = true;
  };
}
