{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_river";
  packages = [pkgs.json-glib];

  libname = "river";
  authors = "kotontrion";
  gir-suffix = "River";
  description = "IPC client for River";

  postUnpack = ''
    rm -rf $sourceRoot/subprojects
    mkdir -p $sourceRoot/subprojects
    cp -r --remove-destination ${src}/../wayland-glib $sourceRoot/subprojects/wayland-glib
  '';
}
