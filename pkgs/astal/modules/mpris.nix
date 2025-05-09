{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_mpris";
  packages = with pkgs; [gvfs json-glib];

  libname = "mpris";
  authors = "Aylur";
  gir-suffix = "Mpris";
  description = "Control mpris players";
}
