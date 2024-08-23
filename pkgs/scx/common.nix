{ fetchFromGitHub }:

rec {
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-r4LhgnFJSWnDAx8x6jY4wgTUSoGfN80vYIrZqKWg4m8=";
    fetchSubmodules = true;
  };
}
