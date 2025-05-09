{
prev,
final,
callPackage,
fetchFromGitHub,
lib
}:
let
  current = lib.trivial.importJSON ./version.json;
  astalSrc = fetchFromGitHub {
    inherit (current) rev hash;
    owner = "Aylur";
    repo = "astal";
  };
  mkPkg = src: astalSrc:
    import src {
      inherit final;
      src = astalSrc;
      pkgs = prev;
      mkAstalPkg = import ./mkAstalPkg.nix src prev;
    };
in
{
  io = mkPkg ./modules/io.nix "${astalSrc}/lib/astal/io";
  astal3 = mkPkg ./modules/astal3.nix "${astalSrc}/lib/astal/gtk3";
  astal4 = mkPkg ./modules/astal4.nix "${astalSrc}/lib/astal/gtk4";
  apps = mkPkg ./modules/apps.nix "${astalSrc}/lib/apps";
  auth = mkPkg ./modules/auth.nix "${astalSrc}/lib/auth";
  battery = mkPkg ./modules/battery.nix "${astalSrc}/lib/battery";
  bluetooth = mkPkg ./modules/bluetooth.nix "${astalSrc}/lib/bluetooth";
  cava = mkPkg ./modules/cava.nix "${astalSrc}/lib/cava";
  greet = mkPkg ./modules/greet.nix "${astalSrc}/lib/greet";
  hyprland = mkPkg ./modules/hyprland.nix "${astalSrc}/lib/hyprland";
  mpris = mkPkg ./modules/mpris.nix "${astalSrc}/lib/mpris";
  network = mkPkg ./modules/network.nix "${astalSrc}/lib/network";
  notifd = mkPkg ./modules/notifd.nix "${astalSrc}/lib/notifd";
  powerprofiles = mkPkg ./modules/powerprofiles.nix "${astalSrc}/lib/powerprofiles";
  river = mkPkg ./modules/river.nix "${astalSrc}/lib/river";
  tray = mkPkg ./modules/tray.nix "${astalSrc}/lib/tray";
  wireplumber = mkPkg ./modules/wireplumber.nix "${astalSrc}/lib/wireplumber";
}
