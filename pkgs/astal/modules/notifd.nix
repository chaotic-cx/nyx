{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_notifd";
  packages = with pkgs; [
    json-glib
    gdk-pixbuf
  ];

  libname = "notifd";
  authors = "Aylur";
  gir-suffix = "Notifd";
  description = "Notification daemon library";
}
