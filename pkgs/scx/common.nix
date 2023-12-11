{ fetchFromGitHub }:

{
  version = "0.1.1.r85.g8ea5850";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "8ea585096722c9433b0663cf2987744b88caa311";
    hash = "sha256-S5d2R3FOO+lgWtm2qpzV479pnjwKYiGBRJwyt3CsGsU=";
    fetchSubmodules = true;
  };

}
