{
  mkAstalPkg,
  pkgs,
  src,
  ...
}:
mkAstalPkg {
  inherit src;
  pname = "astal_wireplumber";
  packages = [pkgs.wireplumber];

  libname = "wireplumber";
  authors = "kotontrion";
  gir-suffix = "Wp";
  description = "Wrapper library over the wireplumber API";
  dependencies = ["WP-0.5"];
}
