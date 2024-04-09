{ prev, ... }:
let
  patch-plasma6 = prev.fetchpatch {
    url = "https://github.com/psifidotos/applet-window-buttons/compare/master...moodyhunter:326382805641d340c9902689b549e4488682f553.patch";
    hash = "sha256-m9ePAVoOYDOHoSAU9/kyI4IAyMAkNIBsela7RWnwFuw=";
  };
in
prev.libsForQt5.applet-window-buttons.overrideAttrs (previousAttrs: {
  patches = [ patch-plasma6 ];

  nativeBuildInputs = with prev; with prev.kdePackages; [
    cmake
    extra-cmake-modules
  ];

  buildInputs = with prev; with prev.kdePackages; [
    kcoreaddons
    kdeclarative
    kdecoration
    ksvg
    libplasma
  ];

  dontWrapQtApps = true;
})
