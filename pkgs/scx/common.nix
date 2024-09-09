{ fetchFromGitHub }:

rec {
  version = "unstable-20240909-249121f";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "249121f15f0844470a8c932cd1bd7b00b043cd50";
    hash = "sha256-XABvEX4SXjubpcd5szJcIy9DBFwXv3/YZ527GFalLyQ=";
    fetchSubmodules = true;
  };
}
