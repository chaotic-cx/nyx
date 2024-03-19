{ fetchFromGitHub }:

rec {
  version = "unstable-20240318-17bce169e";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "0e53e7a00a9ade265dd8fc15d7c8a95fb83d011f";
    hash = "sha256-vRLWhLutjlFfGxfAQeskS5jPuxLDMqp8NoOhUEz3JmI=";
    fetchSubmodules = true;
  };

}
