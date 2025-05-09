{
  pkgs,
  src,
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  inherit src;
  name = "astal_gjs";
  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.astal_io
    pkgs.astal3
  ];
}
