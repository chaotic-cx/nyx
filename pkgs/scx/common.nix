{ fetchFromGitHub }:

rec {
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "v${version}";
    hash = "sha256-nGsLb5+1ONKuQsX4YylTpUo/C8ZNgwEC2K3QvWixMng=";
    fetchSubmodules = true;
  };

}
