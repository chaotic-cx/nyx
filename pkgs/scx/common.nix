{ fetchFromGitHub }:

rec {
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "v${version}";
    hash = "sha256-yY1HQUz9qJqHRjV393Pa4oILakCj0w3IU3jpFh3uzQ0=";
    fetchSubmodules = true;
  };

}
