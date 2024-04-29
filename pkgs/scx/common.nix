{ fetchFromGitHub }:

rec {
  version = "unstable-20240429-d9ea53cb9";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "d9ea53cb9d29c88286e0a7b98556f9f49561521f";
    hash = "sha256-N2sFluMws8tJzT/5twHb3OR+e5CE0G/NSfyfLbSHdv4=";
    fetchSubmodules = true;
  };

}
