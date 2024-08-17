{ callPackage, pkgs }:
let
  src = callPackage ./src.nix { };
in
{
  inherit (src) packageVersion;

  extraConfigureFlags = [
    "--disable-crashreporter"
    "--disable-debug"
    "--disable-debug-js-modules"
    "--disable-debug-symbols"
    "--disable-default-browser-agent"
    "--disable-gpsd"
    "--disable-necko-wifi"
    "--disable-parental-controls"
    "--disable-rust-tests"
    "--disable-tests"
    "--disable-updater"
    "--disable-warnings-as-errors"
    "--disable-webspeech"
    "--enable-bundled-fonts"
    "--enable-eme=widevine"
    "--enable-jxl"
    "--enable-proxy-bypass-protection"
    "--enable-raw"
    "--enable-sandbox"
    "--enable-strip"
    "--with-app-basename=FireDragon"
    "--with-app-name=firedragon"
    "--with-distribution-id=org.garudalinux"
    "--with-unsigned-addon-scopes=app,system"
  ];

  extraNativeBuildInputs = [ pkgs.zstd ];
}
