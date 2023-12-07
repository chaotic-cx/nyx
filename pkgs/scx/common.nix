{ fetchFromGitHub }:

{
  version = "unstable-2023-12-06";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "e38937b5014f4965970bca4099935642761da05e";
    hash = "sha256-ElcMG32fBF8tpdIs3a0l5Xro7JCw8G/ou6znZhXkMkA=";
    fetchSubmodules = true;
  };

}
