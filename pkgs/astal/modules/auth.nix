{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_auth";
  packages = [ pkgs.pam ];

  libname = "auth";
  gir-suffix = "Auth";
  authors = "kotontrion";
  description = "Authentication using pam";
}
