{ config, lib, pkgs, ... }:
let
  cfg = config.chaotic.qtile;

  mainCfg = config.services.xserver.windowManager.qtile;
  pyEnv = pkgs.python3.withPackages (pypkgs: [ (mainCfg.package.unwrapped or mainCfg.package) ] ++ (mainCfg.extraPackages pypkgs));

  runner = backend: pkgs.writeShellScriptBin "start-qtile" ''
    exec ${pyEnv}/bin/qtile start -b ${backend} \
      ${lib.optionalString (mainCfg.configFile != null)
      "--config \"${mainCfg.configFile}\""} "$@"
  '';

  defaultRunner = runner mainCfg.backend;

  session = pkgs.stdenvNoCC.mkDerivation {
    name = "qtile-wayland-session";
    src = pkgs.writeTextDir "entry" ''
      [Desktop Entry]
      Name=QTile
      Comment=QTile Wayland compositor
      Exec=${runner "wayland"}/bin/start-qtile
      Type=Application
    '';
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/wayland-sessions
      cp entry $out/share/wayland-sessions/wayland+qtile.desktop
    '';
    passthru.providedSessions = [ "wayland+qtile" ];
  };
in
{
  options.chaotic.qtile.enable = lib.mkEnableOption "a wayland-session package and a `start-qtile` binary for using with `services.xserver.windowManager.qtile` options";

  config = lib.mkIf cfg.enable {
    services.xserver.windowManager.qtile.enable = true;

    services.displayManager.sessionPackages = [ session ];

    environment.systemPackages = [ defaultRunner ];
  };
}
