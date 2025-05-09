{
  mkAstalPkg,
  pkgs,
  src,
  final,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal3";
  packages = [
    final.astal_io
    pkgs.gtk3
    pkgs.gtk-layer-shell
  ];

  libname = "astal3";
  gir-suffix = "";
  authors = "Aylur";
  description = "Astal GTK3 widget library";
  dependencies = [
    "AstalIO-0.1"
    "Gtk-3.0"
  ];
  repo-path = "astal/gtk3";
}
