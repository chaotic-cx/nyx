{ cmake
, extra-cmake-modules
, fetchFromGitHub
, kdbusaddons
, kdecoration
, kirigami2
, lib
, libSM
, libxcb
, plasma-framework
, plasma-workspace
, stdenv
, wrapQtAppsHook
}:
stdenv.mkDerivation rec {
  pname = "applet-window-appmenu";
  version = "unstable-2023-04-02";

  src = fetchFromGitHub {
    owner = "psifidotos";
    repo = pname;
    rev = "1de99c93b0004b80898081a1acfd1e0be807326a";
    hash = "sha256-PLlZ2qgdge8o1mZOiPOXSmTQv1r34IUmWTmYFGEzNTI=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    wrapQtAppsHook
  ];

  buildInputs = [
    kdbusaddons
    kdecoration
    kirigami2
    libSM
    libxcb
    plasma-framework
    plasma-workspace
  ];

  meta = with lib; {
    description = "Plasma 5 applet in order to show the window appmenu";
    homepage = "https://github.com/psifidotos/applet-window-appmenu";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.dr460nf1r3 ];
  };
}
