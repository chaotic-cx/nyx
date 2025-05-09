{mkAstalPkg, src, ...}:
mkAstalPkg {
  inherit src;
  pname = "astal_io";

  libname = "io";
  gir-suffix = "IO";
  authors = "Aylur";
  description = "Astal Core library";
  repo-path = "astal/io";
  website-path = "io";
}
