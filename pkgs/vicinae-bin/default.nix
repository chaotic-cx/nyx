{ lib, appimageTools, fetchurl, stdenv }:

let
  pname = "vicinae";
  version = "0.15.2";
  src = fetchurl {
    url = "https://github.com/vicinaehq/vicinae/releases/download/v${version}/Vicinae-d22b15390-x86_64.AppImage";
    sha256 = "sha256-WRAOFYBKIWWB3FuVNmxpMYyrVrs5Uj+lLhyP56DUfII=";
  };

in appimageTools.wrapType2 rec {
  inherit pname version src;

  meta = with lib; {
    description = "Vicinae - a high-performance native launcher for your desktop";
    homepage = "https://github.com/vicinaehq/vicinae";
    license = licenses.gpl3;  # Adjust if license differs
    platforms = platforms.linux;
    mainProgram = "vicinae";
    maintainers = with maintainers; [ zstg ];
  };
}
