{ lib
, stdenv
, extra-cmake-modules
, qtbase
, qttools
, shared-mime-info
, fetchFromGitLab
}:

stdenv.mkDerivation {
  pname = "kcoreaddons";
  version = "unstable-2023-10-05";

  outputs = [ "bin" "dev" "out" ];

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "kcoreaddons";
    rev = "80b6893d85bc90fb5d82882c41caa171748c1c63";
    hash = "sha256-QA1vroBBOgzSa4FzcLfFfEF6zY9NaWL0o7RHiw9Qyhs=";
  };

  nativeBuildInputs = [ extra-cmake-modules ];
  buildInputs = [ qttools shared-mime-info ];
  propagatedBuildInputs = [ qtbase ];
  dontWrapQtApps = true;

  meta = with lib; {
    description = "Qt addon library with a collection of non-GUI utilities";
    homepage = "https://kde.org";
    maintainers = with maintainers; [ pedrohlc ];
    license = with licenses; [ lgpl21Plus ];
    platforms = platforms.all;
  };
}
