{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_battery";
  packages = [pkgs.json-glib];

  libname = "battery";
  authors = "Aylur";
  gir-suffix = "Battery";
  description = "DBus proxy for upowerd devices";
}
