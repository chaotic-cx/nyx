{
  prev,
  final,
  callPackage,
  fetchFromGitHub,
  lib,
}:
let
  current = lib.trivial.importJSON ./version.json;
  astalSrc = fetchFromGitHub {
    inherit (current) rev hash;
    owner = "Aylur";
    repo = "astal";
  };
  mkPkg =
    src: astalSrc: isAstalPackage:
    import src {
      inherit final;
      src = astalSrc;
      pkgs = prev;
      mkAstalPkg = import ./mkAstalPkg.nix src {
        inherit isAstalPackage;
        pkgs = prev;
      };
    };
in
{
  io = mkPkg ./modules/io.nix "${astalSrc}/lib/astal/io" true;
  astal3 = mkPkg ./modules/astal3.nix "${astalSrc}/lib/astal/gtk3" true;
  astal4 = mkPkg ./modules/astal4.nix "${astalSrc}/lib/astal/gtk4" true;
  apps = mkPkg ./modules/apps.nix "${astalSrc}/lib/apps" false;
  auth = mkPkg ./modules/auth.nix "${astalSrc}/lib/auth" false;
  battery = mkPkg ./modules/battery.nix "${astalSrc}/lib/battery" false;
  bluetooth = mkPkg ./modules/bluetooth.nix "${astalSrc}/lib/bluetooth" false;
  cava = mkPkg ./modules/cava.nix "${astalSrc}/lib/cava" false;
  greet = mkPkg ./modules/greet.nix "${astalSrc}/lib/greet" false;
  hyprland = mkPkg ./modules/hyprland.nix "${astalSrc}/lib/hyprland" false;
  mpris = mkPkg ./modules/mpris.nix "${astalSrc}/lib/mpris" false;
  network = mkPkg ./modules/network.nix "${astalSrc}/lib/network" false;
  notifd = mkPkg ./modules/notifd.nix "${astalSrc}/lib/notifd" false;
  powerprofiles = mkPkg ./modules/powerprofiles.nix "${astalSrc}/lib/powerprofiles" false;
  river = mkPkg ./modules/river.nix "${astalSrc}/lib/river" false;
  tray = mkPkg ./modules/tray.nix "${astalSrc}/lib/tray" false;
  wireplumber = mkPkg ./modules/wireplumber.nix "${astalSrc}/lib/wireplumber" false;

  astal_gjs = import ./astal_gjs.nix {
    pkgs = final;
    src = "${astalSrc}/lang/gjs";
  };
}
