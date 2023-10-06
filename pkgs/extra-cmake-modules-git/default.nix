{ lib
, stdenv
, fetchFromGitLab
, cmake
, pkg-config
, extra-cmake-modules
}:

stdenv.mkDerivation {
  pname = "extra-cmake-modules";
  version = "unstable-2023-10-07";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "frameworks";
    repo = "extra-cmake-modules";
    rev = "fac8e4edcc285700444222ce04698ce77da6586e";
    hash = "sha256-MpXMSvYoAJHyOTXBGwC1dsgb9SZuG4D0J9Xew6Kf7f8=";
  };

  propagatedBuildInputs = [ cmake pkg-config ];

  inherit (extra-cmake-modules) setupHook;

  meta = with lib; {
    description = "Extra modules and scripts for CMake.";
    platforms = platforms.linux ++ platforms.darwin;
    homepage = "https://invent.kde.org/frameworks/extra-cmake-modules";
    license = licenses.bsd2;
  };
}
