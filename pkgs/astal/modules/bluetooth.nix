{ mkAstalPkg, src, ... }:
mkAstalPkg {
  inherit src;
  pname = "astal_bluetooth";

  libname = "bluetooth";
  authors = "Aylur";
  gir-suffix = "Bluetooth";
  description = "DBus proxy for bluez";
}
