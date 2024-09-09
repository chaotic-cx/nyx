{ fetchFromGitHub }:

rec {
  version = "1.0.4";

  src = fetchFromGitHub {
    owner = "sched-ext";
    repo = "scx";
    rev = "refs/tags/v${version}";
    hash = "sha256-FSeg4E9tpV9KZwVvwPKpcR6TD1wh8g+WjkNYnZeJnuY=";
    fetchSubmodules = true;
  };
}
