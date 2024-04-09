{ prev, ... }:
let
  patch-plasma6 = prev.fetchurl {
    url = "https://github.com/psifidotos/applet-window-buttons/compare/90e37501871a7797e2befc4c524e56f320170780...moodyhunter:326382805641d340c9902689b549e4488682f553.patch";
    hash = "sha256-m9ePAVoOYDOHoSAU9/kyI4IAyMAkNIBsela7RWnwFuw=";
  };
in
prev.libsForQt5.applet-window-buttons.overrideAttrs (previousAttrs: {
  pname = "plasma6-applet-window-buttons";

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

  meta.description = "Plasma 6 applet in order to show window buttons in your panels";
})
