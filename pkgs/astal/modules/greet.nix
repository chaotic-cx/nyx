{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_greet";
  packages = [ pkgs.json-glib ];

  libname = "greet";
  authors = "Aylur";
  gir-suffix = "Greet";
  description = "IPC client for greetd";
}
