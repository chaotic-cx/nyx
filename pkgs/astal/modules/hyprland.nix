{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_hyprland";
  packages = [ pkgs.json-glib ];

  libname = "hyprland";
  authors = "Aylur";
  gir-suffix = "Hyprland";
  description = "IPC client for Hyprland";
}
