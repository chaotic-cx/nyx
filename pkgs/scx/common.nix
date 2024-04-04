{ fetchFromGitHub }:

rec {
  version = "unstable-20240326-5bfd90bd6";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "5bfd90bd64bc72df64456ed187b06bb21d3b873b";
    hash = "sha256-/9BDXe9oaa7xPR3ZnqR6euioo2j55PIjw7K8O2w5M6c=";
    fetchSubmodules = true;
  };

}
