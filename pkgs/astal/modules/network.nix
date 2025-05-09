{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_network";
  packages = [pkgs.networkmanager];

  libname = "network";
  authors = "Aylur";
  gir-suffix = "Network";
  description = "NetworkManager wrapper library";
  dependencies = ["NM-1.0"];
}
