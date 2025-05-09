{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_apps";
  packages = [ pkgs.json-glib ];

  libname = "apps";
  gir-suffix = "Apps";
  authors = "Aylur";
  description = "Application query library";
}
