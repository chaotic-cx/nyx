{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_powerprofiles";
  packages = [pkgs.json-glib];

  libname = "powerprofiles";
  authors = "Aylur";
  gir-suffix = "PowerProfiles";
  description = "DBus proxy for upowerd profiles";
}
